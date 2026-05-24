# Agent TODO: TELNET Fuzzer Iteration Plan

Purpose: incrementally build a useful, maintainable fuzzing capability for this MoonBit TELNET protocol library. Each work slice should be independently useful, tested, and leave the repository in a passing state.

Before and after code changes, follow `AGENTS.md`: run `moon info && moon fmt` and `moon test`; inspect generated `.mbti` diffs for intended public API changes.

## Current status and discovered refinements

- 2026-05-24 pre-implementation survey: repository state has no dedicated fuzz harness or deterministic PRNG helper yet (`find '*fuzz*'` found none). Recent commits focus on parser/encoder performance (`Add native byte search and presized encode APIs`, `Use bulk copies in encode and span helpers`, `Scan parser byte runs in hot paths`), so fuzzer properties should emphasize equivalence across fast paths and fallback paths.
- 2026-05-24 slice 3 pre-implementation survey: repository is clean at `a655a52 Add deterministic fuzz RNG helper`; only `telnet_fuzz_test.mbt` matches `*fuzz*`. Baseline `moon info && moon fmt && moon test` passes with 842 tests. Parser smoke fuzzing should cover multiple parser configs, not just the default, because CR policy and capacity limits change buffering/error paths.
- Refinement for slice 3: include inputs with no `IAC` to exercise the preserve-data fast path and inputs with dense `IAC`/TELNET command bytes to exercise the state machine path.
- Refinement for slice 3: assert parser progress invariants for every generated case (`bytes_consumed == input.length()`, checkpoint `absolute_offset` advances by the input length after `feed`, and `finish` resets to a normal zero-offset parser) across default, immediate-emission, CR-validation, CR-normalization, and hardened zero-capacity configs.
- Refinement for slice 4: compare whole-buffer parsing with one-byte chunks and deterministic random chunk boundaries, including zero-length chunks, because `Parser::feed` accepts empty `Bytes` and should consume zero bytes without changing observable output.
- 2026-05-24 slice 4 pre-implementation survey: repository is clean at `8924401 Add parser smoke fuzz tests`; existing split-equivalence coverage is representative only (`telnet_expanded_behavior_tdd_test.mbt`) and compares raw event arrays, so the fuzz property should normalize adjacent `Data` events and `ByteSpan` ownership differences before comparison.
- Refinement for slice 4: include `finish` output in whole-vs-chunked comparisons so incomplete trailing `IAC`, negotiation verbs, pending CR, and unterminated subnegotiations are checked with identical final diagnostics.
- Refinement for slice 4: assert every chunked feed consumes exactly the chunk length and that zero-length chunks leave the parser checkpoint unchanged, while allowing observable data coalescing differences to collapse in the normalized event stream.
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

### 3. Parser never-panics fuzz smoke test — completed 2026-05-24

- Added deterministic parser smoke fuzz tests in `telnet_fuzz_test.mbt`.
- Coverage includes empty input, all 256 single-byte inputs, targeted TELNET edge seeds, no-`IAC` buffers for the preserve-data fast path, and dense `IAC`/command/CR/LF/NUL/option-code streams for state-machine paths.
- Each case runs through five parser configs: default, immediate data emission, NVT CR validation, CR normalization, and hardened zero-capacity limits.
- Progress/reset invariants asserted for every case:
  - `bytes_consumed == input.length()` after `feed`.
  - checkpoint `absolute_offset == input.length()` after `feed`.
  - buffered lengths never go negative.
  - feed and finish event counts stay bounded by input size.
  - `finish` resets to a normal zero-offset parser.
- No crashes or parser bugs were discovered in this slice, so no reduced regression tests were needed.
- Regression/repro seeds and generation details:
  - Exhaustive single-byte corpus: `[]` and `[0]` through `[255]` under all five configs.
  - Targeted seeds: `[255]`, `[255,255]`, `[255,255,255]`, `[255,241]`, `[255,251]`, `[255,251,1]`, `[255,250]`, `[255,250,31]`, `[255,250,31,255]`, `[255,250,31,255,240]`, `[255,250,31,255,255,255,240]`, `[13]`, `[13,10]`, `[13,0]`, `[13,88]`.
  - No-`IAC` generated cases use seeds `1000 + config_index * 97 + iteration`, lengths `(iteration * 7) % 65`, `iteration = 0..23`.
  - Dense TELNET generated cases use seeds `2000 + config_index * 131 + iteration`, lengths `(iteration * 11 + 3) % 73`, `iteration = 0..23`.
- Commands run for this slice:
  - `git status --short && git log --oneline -8`
  - `find '*fuzz*'`, `find '*_test.mbt'`, `find '*_wbtest.mbt'`
  - `moon info && moon fmt && moon test` before implementation: 842 passed
  - `moon info && moon fmt && moon test` after implementation: 845 passed
  - `moon info && moon fmt && moon test` final verification after TODO update: 845 passed

Acceptance criteria status:

- New fuzz smoke test runs under `moon test` quickly: done.
- Discovered crashes are reduced into fixed regression tests: no crashes found.

Remaining follow-ups:

- Slice 4 should reuse `fuzz_parser_config`, no-`IAC` seeds, and dense TELNET seeds for whole-buffer vs chunked parsing equivalence.
- Slice 13 should improve assertion diagnostics so failures print seed, config index, iteration, length, byte array, and case family.

### 4. Streaming chunk equivalence property — completed 2026-05-24

- Added a deterministic whole-buffer vs chunked parser equivalence property in `telnet_fuzz_test.mbt`.
- The property normalizes adjacent `Data` events and `ByteSpan` ownership differences, then compares feed events plus `finish` events and `complete` status.
- Chunk coverage includes leading/trailing zero-length feeds, one-byte chunks with zero-length feeds between bytes, every two-chunk split for inputs up to 16 bytes, and three deterministic random chunk patterns for each generated input.
- Chunked feeds now assert `bytes_consumed == chunk.length()` and that zero-length chunks emit no events and leave the checkpoint unchanged.
- Fixed parser bugs exposed by the property:
  - zero-length `Parser::feed` could clear pending CR state;
  - split `ValidateNvt` CR LF dropped the CR byte;
  - split `NormalizeToLf` CR followed by an ordinary byte dropped the CR byte;
  - CR at the end of a chunk with preceding data was emitted too early instead of becoming pending;
  - validate-policy errors could be ordered differently around buffered data and could consume an `IAC` byte after a split CR instead of reprocessing it as TELNET framing.
- Reduced regression seeds now live in the named test `parser streaming fuzz keeps empty feeds and pending CR equivalent`:
  - `config_index=2`, seed `3001`, input `[13, 10]` for split validate CR LF.
  - `config_index=2`, generated seed `7515`, input `[254, 73, 240, 34, 255, 134, 252, 27, 13, 240, 97, 218]` for validate-policy error ordering with preceding data.
  - `config_index=2`, generated seed `7526`, input `[31, 31, 3, 39, 13, 255, 251]` for split CR before `IAC` reprocessing.
  - `config_index=3`, seed `3002`, input `[13, 88]` for normalize CR followed by ordinary data.
  - Empty-feed regression: after feeding `[13]` under `config_index=3`, feeding `Bytes::new(0)` consumes zero bytes, emits no events, and preserves the checkpoint.
- Generated coverage details:
  - Targeted seeds: `[]`, `[255]`, `[255,255]`, `[255,251,1]`, `[255,250,31,255,255,255,240]`, `[13]`, `[13,10]`, `[13,0]`, `[13,88]` across all five `fuzz_parser_config` variants.
  - No-`IAC` generated cases use seeds `4000 + config_index * 97 + iteration`, lengths `(iteration * 5) % 33`, `iteration = 0..15`.
  - Dense TELNET generated cases use seeds `6000 + config_index * 131 + iteration`, lengths `(iteration * 7 + 5) % 41`, `iteration = 0..15`.
  - Random chunk patterns use seeds `property_seed + pattern * 655`, `pattern = 0..2`; generated property seeds are `5000 + config_index * 257 + iteration` for no-`IAC` cases and `7000 + config_index * 257 + iteration` for dense TELNET cases.
- Commands run for this slice:
  - `git status --short && git log --oneline -8`
  - `find '*fuzz*'`, `find '*_test.mbt'`, `find '*_wbtest.mbt'`
  - `moon info && moon fmt && moon test` before implementation: 845 passed
  - `moon info && moon fmt && moon test` during implementation: compile failed on invalid `_` loop variable in `fuzz_one_byte_chunks`
  - `moon info && moon fmt && moon test` during implementation: 847 passed, 1 failed before parser fixes
  - `moon test --help | head -80`
  - `python3 - <<'PY' ... PY` to map deterministic dense-stream seeds to byte arrays while reducing failures
  - `moon test telnet_fuzz_test.mbt -f 'parser streaming fuzz covers generated fast paths and dense streams'` while reducing parser bugs: failed with seed `7515` single-byte mismatch, failed with seed `7515` split `9`, failed with seed `7526`, then passed after fixes
  - `moon info && moon fmt && moon test` final verification: 848 passed

Acceptance criteria status:

- Whole-vs-streaming equivalence property is tested: done.
- Any parser-state API limitations are documented: done; zero-length feeds are now fixed to be state-preserving rather than documented as a limitation.
- `moon test` passes: done.

Remaining follow-ups:

- Slice 5 should reuse normalized event comparison when round-tripping parser output so `ByteSpan` ownership differences do not cause false failures.
- Slice 13 should expand failure diagnostics to include config index, iteration, generated length, byte array, parser config, and whole/chunked mode; slice 4 currently prints only seed/length/split or random pattern before aborting.


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
