# Agent TODO: TELNET Fuzzer Iteration Plan

Purpose: incrementally build a useful, maintainable fuzzing capability for this MoonBit TELNET protocol library. Each work slice should be independently useful, tested, and leave the repository in a passing state.

Before and after code changes, follow `AGENTS.md`: run `moon info && moon fmt` and `moon test`; inspect generated `.mbti` diffs for intended public API changes.

## Current status and discovered refinements

- 2026-05-24 pre-implementation survey: repository state has no dedicated fuzz harness or deterministic PRNG helper yet (`find '*fuzz*'` found none). Recent commits focus on parser/encoder performance (`Add native byte search and presized encode APIs`, `Use bulk copies in encode and span helpers`, `Scan parser byte runs in hot paths`), so fuzzer properties should emphasize equivalence across fast paths and fallback paths.
- Refinement for slice 3: include inputs with no `IAC` to exercise the preserve-data fast path and inputs with dense `IAC`/TELNET command bytes to exercise the state machine path.
- Refinement for slice 4: compare whole-buffer parsing with one-byte chunks and deterministic random chunk boundaries, including zero-length chunks, because `Parser::feed` accepts empty `Bytes` and should consume zero bytes without changing observable output.
- Refinement for slice 5: when round-tripping canonical escaped data, explicitly include spans that are suffixes of larger `Bytes` so `ByteSpan::start`/`length` handling is covered.
- Refinement for slice 13: failure output should include the PRNG seed, iteration, generated length, byte array, parser config, and whether the case was whole-buffer or chunked.

## Operating rules for fuzzer agents

- Keep fuzz tests deterministic in normal CI/test runs. Use fixed seeds and bounded iteration counts unless explicitly adding a separate long-running target.
- Prefer small, reviewable commits/work slices.
- Preserve a fast default `moon test` experience. Expensive fuzzing should live behind a separate command/package or environment flag.
- When a fuzz case finds a bug, shrink or distill it into a named regression test before or alongside the fix.
- Document protocol assumptions in `docs/wiki/` when adding semantic fuzz properties.
- Avoid adding new public API unless it clearly improves testability or usability.

## Work slices

### 1. Survey current parser and test surface

- Read `telnet.mbt`, `api.mbt`, and existing `*_test.mbt` / `*_wbtest.mbt` files.
- Identify public parser, encoder, and negotiator entry points.
- Record current parsing modes and failure/partial-input behavior in a short section in this file or a new fuzzing note under `docs/wiki/`.
- Find existing edge-case tests that should become fuzz seeds.

Acceptance criteria:

- Clear list of fuzzable APIs.
- Clear list of seed cases harvested from existing tests.
- `moon test` passes.

### 2. Add deterministic pseudo-random generator helper for tests — completed 2026-05-24

- Added `telnet_fuzz_test.mbt` with a test-only deterministic `FuzzRng` helper.
- Supports bytes, bounded integers, booleans, chunk boundaries, and reproducible byte buffers.
- Uses small integer arithmetic (`state = (state * 25173 + 13849) % 65521`) to avoid target-dependent overflow behavior.
- Regression/repro seeds:
  - `fuzz_rng(1)` first states: `39022`, `23823`, `62036`.
  - `fuzz_bytes(1, 8)` yields `[110, 15, 84, 131, 124, 254, 14, 8]`.
  - `fuzz_rng(0)` normalizes to seed `1`; `fuzz_rng(-1)` normalizes to state `65520`.
- Commands run for this slice:
  - `git status --short && git log --oneline -5`
  - `find '*fuzz*'`, `find '*_test.mbt'`, `find '*_wbtest.mbt'`
  - `moon info && moon fmt && moon test` before implementation: 839 passed
  - `moon info && moon fmt && moon test` after implementation: 842 passed

Acceptance criteria status:

- Test helper is target-stable: done.
- No production API changes unless justified: done; test file only.
- `moon test` passes: done.

Remaining follow-ups:

- Use `FuzzRng` in slice 3 parser no-panic smoke tests with both fast-path data and dense TELNET control byte generation.
- Use `chunk_boundary` in slice 4 whole-vs-streaming equivalence tests, including zero-length chunk cases.

### 3. Parser never-panics fuzz smoke test

- Add bounded random byte-array fuzz tests that feed arbitrary bytes to the TELNET parser.
- Include zero-length input, one-byte input, all 256 single-byte inputs if practical, and random buffers with heavy bias toward `IAC` (`0xff`), command bytes, CR, LF, NUL, and option codes.
- Assert no panic, no infinite loop, and no obviously invalid parser progress behavior.
- Keep default iterations modest enough for `moon test`.

Acceptance criteria:

- New fuzz smoke test runs under `moon test` quickly.
- Discovered crashes are reduced into fixed regression tests.

### 4. Streaming chunk equivalence property

- For arbitrary byte buffers, compare parsing the whole buffer with parsing it split across deterministic random chunk boundaries.
- Exercise chunk sizes of 0/1 where supported, single-byte chunks, two chunks at every possible split for small inputs, and random chunk patterns for larger inputs.
- Define and document expected behavior for incomplete trailing TELNET commands/subnegotiations.

Acceptance criteria:

- Whole-vs-streaming equivalence property is tested.
- Any parser-state API limitations are documented.
- `moon test` passes.

### 5. Encode-then-parse valid event corpus

- Generate valid TELNET data/events/commands/options using a deterministic generator.
- Encode generated events/frames and parse the resulting bytes.
- Assert the parsed result is equivalent to the original, allowing documented normalizations.
- Cover data bytes requiring `IAC` escaping.

Acceptance criteria:

- Round-trip property covers data, command, option-negotiation, and subnegotiation cases.
- Normalization exceptions are explicit and tested.

### 6. Parse-then-encode stability property

- Parse arbitrary byte sequences into whatever structured representation is available.
- Re-encode parseable/complete outputs and parse again.
- Assert idempotence or a documented stable normal form.
- Exclude malformed/incomplete tails only with explicit checks.

Acceptance criteria:

- Stable normal-form property exists for parseable streams.
- Known non-idempotent cases are documented with rationale.

### 7. TELNET `IAC` escaping stress cases

- Add targeted generator and regression tests for `IAC` handling:
  - data byte `0xff` encoded as `IAC IAC`
  - bare trailing `IAC`
  - repeated `IAC` runs of different lengths
  - `IAC` inside `SB ... SE`
  - escaped `IAC IAC` inside subnegotiation payloads
  - command byte following `IAC` at chunk boundary
- Ensure both parser and encoder behavior is covered.

Acceptance criteria:

- Focused tests around all important `IAC` edge cases.
- Any discovered ambiguity documented in `docs/wiki/`.

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
3. Pick the next highest-value incomplete slice that can be finished in one run.
4. Implement tests first when practical.
5. Fix discovered bugs or document limitations.
6. Run `moon info && moon fmt && moon test`.
7. Update this file with completed work, remaining follow-ups, seeds, and any reproduction commands.
8. Leave the repo in a clean, understandable state.
