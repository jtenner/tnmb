# Agent TODO: TELNET Fuzzer Active Backlog

Purpose: track only active, incomplete fuzzer-improvement work for this MoonBit TELNET protocol library. Completed tasks, historical run notes, and closed reproduction details should not be kept in this file; they belong in git history, commit messages, tests, or docs.

Before and after code changes, follow `AGENTS.md`: run `moon info && moon fmt` and `moon test`; inspect generated `.mbti` diffs for intended public API changes.

## Backlog policy

- Only active todo tasks should be placed in this file.
- Remove a task from this backlog once it is completed and committed.
- Keep entries concise, actionable, and independently reviewable.
- If a fuzz case exposes a bug, reduce it into a named regression test and keep any long-term follow-up here only if work remains.

## Latest completed slice

- Completed slice 21, shared runnable fuzzer helpers, on 2026-05-24.
- Added `cmd/fuzz-common` for shared pure helper logic used by `cmd/fuzz` and `cmd/fuzz-native`: deterministic RNG, TELNET-biased byte generation, parser config presets, byte literals/slicing/concatenation, `ByteSpan` conversion, and one-byte chunks.
- Left `telnet_fuzz_test.mbt` helper copies local by design so fast package tests do not make the public TELNET package depend on command-only fuzz internals; documented the remaining harness-local observation/failure-format duplication in `docs/wiki/10-fuzzing.md`.
- No production parser bug was exposed in this slice.
- Remaining follow-ups: continue with slice 22 (native coverage-guided fuzzer validation/persistent or file-input modes).
- Reproduction seeds/details:
  - No new fuzz failure seed was discovered.
  - No generated reproduction wire was added.
  - Shared-helper smoke probe used deterministic command seed `424242`, 32 iterations, max length 32, target `all`, checksum `4244`.
  - CI fuzz profile used seed `20260524`, 4096 iterations, max length 192, target `all`, checksum `3019894`.
  - Native smoke probe used stdin wire `bytes([255, 255])`, default max input bytes `4096`, checksum `20`.
- Commands run:
  - `git status --short && git log --oneline -5`
  - `git status --short && printf '\n--- recent commits ---\n' && git log --oneline -8 && printf '\n--- changed files in last 3 commits ---\n' && git show --stat --oneline --name-only --no-renames HEAD~3..HEAD`
  - `python3 - <<'PY' ... PY`: listed helper definitions in `telnet_fuzz_test.mbt`, `cmd/fuzz/main.mbt`, and `cmd/fuzz-native/main.mbt`.
  - `moon info`: passed after adding `cmd/fuzz-common`.
  - `moon run cmd/fuzz -- 424242 32 32 all && printf '\377\377' | moon run --target native cmd/fuzz-native`: passed.
  - `tools/build-fuzz-native.sh && printf '\377\377' | _build/fuzz-native/telnet-fuzz-native`: passed.
  - `moon info && moon fmt`: passed.
  - `moon test`: passed with 876 tests.
  - `git status --short && printf '\n--- diff stat ---\n' && git diff --stat && printf '\n--- mbti diff ---\n' && git diff -- pkg.generated.mbti cmd/fuzz/pkg.generated.mbti cmd/fuzz-native/pkg.generated.mbti cmd/fuzz-common/pkg.generated.mbti && printf '\n--- whitespace ---\n' && git diff --check`: whitespace check found regenerated blank EOF lines in generated `.mbti` files.
  - `python3 - <<'PY' ... PY && git diff --check`: normalized generated `.mbti` EOF whitespace and passed whitespace check.
  - `moon info && moon fmt && moon test`: final verification passed with 876 tests after the todo update.
  - `git status --short && printf '\n--- diff stat ---\n' && git diff --stat && printf '\n--- mbti diff ---\n' && git diff -- pkg.generated.mbti cmd/fuzz/pkg.generated.mbti cmd/fuzz-native/pkg.generated.mbti cmd/fuzz-common/pkg.generated.mbti && printf '\n--- whitespace ---\n' && git diff --check`: final whitespace check again found regenerated blank EOF lines in generated `.mbti` files.
  - `python3 - <<'PY' ... PY && git diff --check`: normalized generated `.mbti` EOF whitespace again and passed final whitespace check.
  - `moon run cmd/fuzz -- ci`: passed with checksum `3019894`.

## Active work slices

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
