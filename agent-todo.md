# Agent TODO: TELNET Fuzzer Active Backlog

Purpose: track only active, incomplete fuzzer-improvement work for this MoonBit TELNET protocol library. Completed tasks, historical run notes, and closed reproduction details should not be kept in this file; they belong in git history, commit messages, tests, or docs.

Before and after code changes, follow `AGENTS.md`: run `moon info && moon fmt` and `moon test`; inspect generated `.mbti` diffs for intended public API changes.

## Backlog policy

- Only active todo tasks should be placed in this file.
- Remove a task from this backlog once it is completed and committed.
- Keep entries concise, actionable, and independently reviewable.
- If a fuzz case exposes a bug, reduce it into a named regression test and keep any long-term follow-up here only if work remains.

## Latest completed slice

- Completed slice 17, performance and allocation guardrails, on 2026-05-24.
- Added deterministic parser guardrail fuzz tests for large bounded no-IAC data, escaped-IAC runs, long negotiation streams, and oversized subnegotiation discard/resume behavior.
- The guardrails assert full input consumption, exact checkpoint progress, zero retained parser buffers after complete frames, linear event counts, bounded data chunking, and single-error discard behavior for a 512-byte oversized subnegotiation followed by 64 negotiations.
- Verified `cmd/bench/` already keeps related worst-case patterns performance-visible (`parser_plain_*`, dense/sparse escaped IAC, negotiation-heavy, subnegotiation-heavy, malformed-error-heavy, and e2e shell/output cases), so no benchmark change was needed for this slice.
- No production parser bug was exposed in this slice.
- Remaining follow-ups: continue with slice 18 (differential reference checks), slice 19 (broader fuzz documentation), slice 20 (regression backlog cleanup), slice 21 (helper deduplication research), and slice 22 (native coverage-guided fuzzer validation/persistent or file-input modes).
- Reproduction seeds/details:
  - No new fuzz failure seed was discovered.
  - Large no-IAC guardrail uses `fuzz_no_iac_bytes(16000, 2048)` with `max_data_chunk_bytes=64` and expects 32 data events.
  - Oversized subnegotiation guardrail uses `fuzz_no_iac_bytes(16017, 512)` inside `IAC SB NAWS ... IAC SE`, followed by 64 generated WILL/WONT/DO/DONT negotiations; it expects one `SubnegotiationTooLarge` error and 64 negotiation events.
  - Escaped-IAC guardrail uses 512 `IAC` bytes, parsed as 256 escaped data bytes with 256 events.
  - Long negotiation guardrail uses 512 complete negotiation triplets and expects exactly 512 negotiation events.
- Commands run:
  - `git status --short && git log --oneline -5`
  - `git status --short && printf '\n--- stat ---\n' && git show --stat --oneline HEAD`
  - `git diff -- agent-todo.md telnet_fuzz_test.mbt | sed -n '1,260p'`
  - `moon test`: 874 tests passed.
  - `moon info && moon fmt && moon test`: no public API diff intended; 874 tests passed (run before and after the todo update).
  - `git status --short && printf '\n--- mbti diff ---\n' && git diff -- pkg.generated.mbti cmd/fuzz/pkg.generated.mbti cmd/fuzz-native/pkg.generated.mbti`
  - `git diff --check` / `git status --short && git diff --check && git diff --stat` (initially flagged generated `.mbti` blank lines at EOF after each `moon info`; normalized generated files back to no diff).
  - `python3 - <<'PY' ... PY && git diff --check`: whitespace check passed after normalization.

## Active work slices

### 18. Differential checks against a simple reference model

- Build a tiny test-only reference scanner for a small subset of TELNET: data bytes, escaped `IAC`, simple commands, and subnegotiation boundaries.
- Compare production parser results against the reference model for that subset.
- Keep reference intentionally dumb and independent from production implementation.

Acceptance criteria:

- Differential property catches parser drift for core framing.
- Reference model limitations are documented.

### 19. Fuzz documentation

- Add or update `docs/wiki/` with a fuzzing/testing page or section:
  - what properties are tested
  - how to run fast fuzz tests
  - how to run long fuzz tests
  - how to reproduce failures (build on the slice 13 note now in `06-testing-compliance.md`)
  - how to add new seeds/regressions
- Link to relevant TELNET protocol docs already used by the wiki.

Acceptance criteria:

- Documentation is accurate and command examples work.
- Any protocol claims cite existing source docs or authoritative URLs.

### 20. Regression backlog cleanup

- Search TODOs, skipped tests, and comments created during fuzzing.
- Convert known failures into either fixed bugs or explicit documented limitations.
- Remove dead experiments and unused helpers.

Acceptance criteria:

- No unexplained TODOs or skipped fuzz tests remain.
- `moon info && moon fmt && moon test` passes.

### 21. Shared fuzzer helper research

- Investigate whether deterministic RNG, TELNET-biased input generation, observation normalization, and failure formatting can be shared between `telnet_fuzz_test.mbt` and `cmd/fuzz` without exposing test-only API from the public package.
- If MoonBit package boundaries make sharing awkward, document the duplication and keep command/test helpers intentionally independent.
- Preserve fast default tests and keep `cmd/fuzz` runnable.

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
