# Agent TODO: TELNET Fuzzer Active Backlog

Purpose: track only active, incomplete fuzzer-improvement work for this MoonBit TELNET protocol library. Completed tasks, historical run notes, and closed reproduction details should not be kept in this file; they belong in git history, commit messages, tests, or docs.

Before and after code changes, follow `AGENTS.md`: run `moon info && moon fmt` and `moon test`; inspect generated `.mbti` diffs for intended public API changes.

## Backlog policy

- Only active todo tasks should be placed in this file.
- Remove a task from this backlog once it is completed and committed.
- Keep entries concise, actionable, and independently reviewable.
- If a fuzz case exposes a bug, reduce it into a named regression test and keep any long-term follow-up here only if work remains.

## Active refinements

- Failure output should include enough detail to reproduce a case: PRNG seed, iteration, generated length, byte array, parser config, whether the case was whole-buffer or chunked, encoded wire bytes when relevant, and expected/observed normalized events when practical.

## Latest completed slice

- Completed slice 11, CR/LF/NUL text handling fuzz cases, on 2026-05-24.
- Added deterministic newline fuzz helpers with a small independent no-IAC reference model for `Preserve`, `ValidateNvt`, and `NormalizeToLf` CR policies.
- Added targeted and generated CR/LF/NUL-biased cases that compare expected normalized events across whole-buffer parsing, all representative split points, and one-byte feeds.
- Added explicit command-boundary regression coverage for CR before/after TELNET IAC commands and documented current binary-mode assumptions in `docs/wiki/06-testing-compliance.md`.
- No production parser bug was exposed in this slice.
- Remaining follow-ups: continue with slice 12 (RFC-inspired seed corpus) and the still-active general failure-output refinement for older fuzz helpers.
- Reproduction seeds/details:
  - Targeted no-IAC wires: `[]`, `[13]`, `[10]`, `[0]`, `[13, 10]`, `[13, 0]`, `[13, 88]`, `[65, 13, 10, 66]`, `[65, 13, 0, 66]`, `[65, 13, 88, 13, 10, 0]`, `[13, 13, 10, 13, 0, 10]`, and `[0, 13, 0, 10, 13, 90]` under all three CR policies.
  - Generated no-IAC CR/LF/NUL-biased wires use seeds `14100 + policy_index * 257 + iteration`, policy indexes `0..2`, iterations `0..23`, and lengths `(iteration * 7 + policy_index * 3) % 37`.
  - Preserve/binary-like mixed-data seed `14200` uses `[0, 13, 10, 128, 254, 13, 0, 42]`.
  - Command-boundary seeds `14300..14303` use `[13, 255, 241, 10]` and `[255, 241, 13, 10, 65]`.
- Commands run:
  - `git status --short && git log --oneline -5`
  - `find '*fuzz*'`
  - `moon info && moon fmt && moon test` before implementation: 865 passed
  - `moon info && moon fmt && moon test` after implementation: 869 passed
  - `git status --short && git diff --stat`
  - `git diff -- telnet_fuzz_test.mbt docs/wiki/06-testing-compliance.md agent-todo.md | sed -n '1,260p'`
  - `moon info && moon fmt && moon test && git diff --check && git status --short` final verification: 869 passed; working tree contained only this run's three modified files (run twice after implementation/TODO updates; both passed)

## Active work slices

### 12. Add seed corpus from RFC-inspired examples

- Collect small TELNET byte sequences from project wiki/spec tests and RFC-derived examples already cited in docs.
- Store seeds in code or a small test fixture format, whichever is idiomatic for the repo.
- Ensure every seed runs through no-panic, streaming equivalence, and round-trip checks where applicable.

Acceptance criteria:

- Named seed corpus exists.
- Seeds are easy to extend when bugs are found.

### 13. Failure minimization workflow

- Add a developer note describing how to reproduce a fuzz failure by seed, iteration, and input bytes.
- Make fuzz tests print or snapshot enough data to reproduce failures without overwhelming normal output.
- Consider a tiny helper that formats failing bytes as MoonBit array literals.

Acceptance criteria:

- A failed fuzz assertion points to a seed and minimal reproduction path.
- Documentation explains how to promote a failure into a regression test.

### 14. Separate long-running fuzz command/package

- Add `cmd/fuzz/` or equivalent only if MoonBit package layout supports it cleanly.
- Provide a long-running deterministic fuzz loop configurable by environment variables or arguments: seed, iterations, max length, target/property.
- Keep default test fuzzing fast; long fuzzing should run via a separate command.
- If command-line argument handling is awkward, document the chosen invocation clearly.

Acceptance criteria:

- A developer can run an extended fuzz session locally without changing tests.
- `moon run cmd/fuzz` or documented equivalent works.

### 15. CI-friendly fuzz mode

- Add a moderately larger fuzz run suitable for CI if project CI exists.
- Keep runtime bounded and configurable.
- Ensure failures are deterministic and reproducible.
- Avoid flaky timing-based assertions.

Acceptance criteria:

- CI can run the fuzzer without excessive runtime.
- Local fast tests remain fast.

### 16. Coverage-guided fuzzing research spike

- Investigate whether MoonBit/native output can be connected to AFL++, libFuzzer, honggfuzz, or another coverage-guided engine.
- Prefer documented, repeatable setup over clever one-off scripts.
- If feasible, add an experimental harness under `cmd/fuzz-native/` or `tools/` with clear docs.
- If not feasible, document blockers and keep deterministic property fuzzer as primary approach.

Acceptance criteria:

- Feasibility decision captured in docs.
- No fragile external dependency is required for normal tests.

### 17. Performance and allocation guardrails

- Add fuzz cases with large but bounded payloads and long negotiation streams.
- Assert parser makes progress and avoids pathological response growth.
- Consider benchmark cases in `cmd/bench/` for worst-case byte patterns discovered by fuzzing.

Acceptance criteria:

- Known worst-case patterns are benchmarked or tested.
- No unbounded response amplification for small inputs.

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
  - how to reproduce failures
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
