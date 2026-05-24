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

- Completed slice 12, RFC-inspired seed corpus, on 2026-05-24.
- Added a named in-code seed corpus covering RFC 854 data/IAC/command/negotiation framing, common option subnegotiations from the documented verification corpus, malformed tails, START_TLS negotiation, and a private-option sample.
- Each seed now runs through parser smoke invariants and streaming equivalence across all five fuzz parser configurations; parse/encode stability is checked for seeds marked as encodable, while malformed/excluded seeds assert the expected non-encodable path.
- Seed-corpus failures print case name, seed, config index, wire length, byte array, and expected/observed normalized events where relevant.
- No production parser bug was exposed in this slice.
- Remaining follow-ups: continue with slice 13 (failure minimization workflow) and the still-active general failure-output refinement for older fuzz helpers.
- Reproduction seeds/details:
  - Named seed corpus `fuzz_rfc_inspired_seed_corpus()` has seeds `15000..15019`.
  - Encodable/stability seeds: `15000` data `Hello`; `15001` escaped IAC data; `15002..15003` simple commands; `15004..15007` common negotiation/mixed streams; `15011` NAWS 80x24; `15012..15013` TERMINAL-TYPE SEND/IS; `15014` NEW-ENVIRON empty IS; `15015` CHARSET UTF-8 request; `15016` LINEMODE mode sample; `15017` START_TLS DO/WILL; `15018` private option 93 negotiation.
  - Excluded malformed/non-encodable seeds: `15008` incomplete IAC, `15009` incomplete negotiation, `15010` incomplete subnegotiation, and `15019` strict invalid-command sample.
- Commands run:
  - `git status --short && echo '--- recent commits ---' && git log --oneline -5`
  - `moon info && moon fmt && moon test` before implementation: 869 passed
  - `moon info && moon fmt && moon test` after implementation: 870 passed
  - `git status --short && git diff --stat && git diff -- telnet_fuzz_test.mbt agent-todo.md | sed -n '1,280p'`
  - `git diff -- pkg.generated.mbti`
  - `moon info && moon fmt && moon test && git diff --check && git status --short` final verification: 870 passed; working tree contained only `agent-todo.md` and `telnet_fuzz_test.mbt`

## Active work slices

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
