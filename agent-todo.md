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

- Completed slice 7, TELNET `IAC` escaping stress cases, on 2026-05-24.
- Added focused deterministic tests for canonical data escaping, bare/trailing `IAC`, repeated `IAC` runs, escaped `IAC IAC` inside subnegotiation payloads, embedded `IAC` commands inside `SB ... SE`, and command bytes following `IAC` at chunk boundaries.
- Added `IAC` stress assertion helpers that print case name, seed, length, wire bytes, and expected/observed normalized events for easy regression promotion.
- No parser or encoder bugs were discovered, so no reduced regression fixes or wiki ambiguity notes were needed.
- Remaining follow-ups: continue with slice 8 (subnegotiation fuzzer) and the still-active general failure-output refinement for non-`IAC` fuzz helpers.
- Reproduction seeds/details:
  - Encoder data escaping: `11000` single data `0xff`, `11001` mixed data `[65, 255, 66, 255]`.
  - Repeated `IAC` runs: `11101..11109` for run lengths `1..9`; odd lengths document incomplete trailing `IAC` and even lengths document escaped data bytes.
  - Subnegotiation `IAC` handling: `11200` escaped payload `[1, 255, 2, 255]`, `11201` embedded `IAC NOP` excluded from payload with an `InvalidCommandByte`, `11202` incomplete subnegotiation after trailing `IAC`.
  - Command-boundary cases: `11300` encoded `NOP`, `11301` data/command/data streaming splits, `11302` explicit chunks `[2, 1, 1]` for `[65, IAC, NOP, 66]`.
- Commands run:
  - `git status --short && git log --oneline -5`
  - `find '*fuzz*'`
  - `moon info && moon fmt && moon test` before implementation: 853 passed
  - `moon info && moon fmt && moon test` after implementation: 856 passed
  - `git status --short && git diff --stat`
  - `git diff -- pkg.generated.mbti`
  - `git diff -- telnet_fuzz_test.mbt | sed -n '1,260p'`
  - `moon info && moon fmt && moon test` final verification after TODO update: 856 passed

## Active work slices

### 8. Subnegotiation fuzzer

- Generate `IAC SB <option> <payload> IAC SE` frames with random option and payload bytes.
- Generate malformed frames: missing `SE`, missing option, embedded commands, escaped `IAC`, and nested `SB` markers.
- Assert parser never panics and complete valid frames round-trip where supported.
- Add regression tests for historically tricky subnegotiation cases.

Acceptance criteria:

- Subnegotiation parser has both valid and malformed fuzz coverage.
- Tests include boundary and streaming splits inside payload and around `IAC SE`.

### 9. Negotiation command sequence fuzzer

- Generate random sequences of `DO`, `DONT`, `WILL`, and `WONT` with known and unknown option codes.
- Feed them through any negotiator/state machine APIs.
- Assert no panic, bounded output, and no impossible final state such as simultaneously enabled and disabled in the same direction if the model represents those states.
- Check loop-prevention behavior where applicable.

Acceptance criteria:

- Negotiator fuzz/property test exists.
- Invariants are documented and asserted.

### 10. Unknown option and command catalog coverage

- Iterate over all 0..255 option codes and all relevant command bytes.
- Ensure unknown/registered option mapping is stable and parser behavior is safe.
- Add generated tests for IANA option catalog coverage if the repo already has option mapping helpers.

Acceptance criteria:

- Exhaustive byte-level coverage for option/command mapping helpers.
- Public behavior for unknown values is documented by tests.

### 11. CR/LF/NUL text handling fuzz cases

- Generate text/data streams biased around CR, LF, CR LF, CR NUL, bare CR, and mixed binary bytes.
- Assert documented TELNET newline behavior and binary-mode behavior if implemented.
- Add focused regressions for any discovered newline normalization bug.

Acceptance criteria:

- Text/newline handling has fuzz and regression coverage.
- Binary/text mode assumptions are documented.

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
