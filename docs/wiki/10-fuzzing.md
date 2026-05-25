# 10 — Fuzzing Guide

This page is the operational guide for the TELNET fuzzing layers. It complements
[06-testing-compliance.md](06-testing-compliance.md) with concrete commands,
property names, and reproduction workflow. Protocol expectations come from the
same sources listed in [00-sources.md](00-sources.md): RFC 854 for TELNET byte
stream framing, NVT CR/LF/NUL rules, IAC escaping, and option-negotiation
framing; RFC 855 for option structure; RFC 1143 for negotiation-loop avoidance;
and the IANA TELNET option registry for option-code assignments.

## Fuzzing layers

| Layer | Location | Default? | Purpose |
|---|---|---:|---|
| Deterministic property tests | `telnet_fuzz_test.mbt` | Yes, via `moon test` | Fast regression suite for parser, encoder, option catalog, and negotiation invariants. |
| Long deterministic runner | `cmd/fuzz` | No | Reproducible extended exploration with configurable seed, iteration count, length, and target. |
| Runnable harness support | `cmd/fuzz-common` | No | Shared pure helpers for the deterministic and native runnable harnesses. |
| Native stdin harness | `cmd/fuzz-native` plus `tools/build-fuzz-native.sh` | No | Optional process-level target for AFL++ or another native coverage-guided engine. |
| Native seed corpus | `tools/fuzz-corpus/seeds/` | No | Tiny initial inputs for coverage-guided mutation. |

Keep the boundary strict: `moon test` must stay deterministic and fast. Longer
or instrumented fuzzing belongs behind explicit `moon run cmd/fuzz ...`,
`moon run --target wasm cmd/fuzz ...`, `moon run --target wasm-gc cmd/fuzz ...`,
`moon run --target native cmd/fuzz-native`, or external fuzzer commands.

## Properties covered by the fast suite

`telnet_fuzz_test.mbt` keeps reduced regressions and small generated sweeps in
the normal test suite. It currently covers these property families:

- deterministic RNG and failure-format helpers, so generated cases can be
  reproduced exactly;
- parser smoke coverage for empty input, all single bytes, TELNET edge seeds,
  no-IAC data paths, dense control streams, malformed tails, and strict vs
  permissive command handling;
- streaming equivalence across empty feeds, one-byte feeds, generated chunk
  boundaries, pending CR states, and TELNET command/subnegotiation boundaries;
- differential checks against a deliberately simple core TELNET scanner for
  complete data, escaped-IAC, simple command, negotiation, and subnegotiation
  streams;
- NVT CR/LF/NUL policy checks for `Preserve`, `ValidateNvt`, and
  `NormalizeToLf` parser configurations;
- encoder/parser roundtrip and parse-encode stability for valid generated
  frames, with malformed tails explicitly excluded where they are not stable
  encodable events;
- IAC stress cases for escaped data, repeated IAC runs, subnegotiation escapes,
  and command boundaries;
- subnegotiation boundary, malformed-frame, and oversized-discard behavior;
- negotiation-state sequences, including generated peer commands and interleaved
  local requests that exercise the RFC 1143 Q-method state machine;
- command and option catalog mapping coverage against the IANA option registry;
- RFC-inspired seed corpus cases recorded in `tools/fuzz-corpus/seeds/`; and
- parser performance guardrails that bound event growth for large data, escaped
  IAC, long negotiation streams, and discarded oversized subnegotiations.

## Fast local and CI commands

Run the default deterministic suite:

```sh
moon info && moon fmt
moon test
```

Run the extended deterministic CI fuzz profile used by
`.github/workflows/ci.yml`:

```sh
moon run cmd/fuzz -- ci
moon run --target wasm cmd/fuzz -- ci
moon run --target wasm-gc cmd/fuzz -- ci
```

The CI profile is intentionally bounded: seed `20260524`, 4096 iterations,
maximum generated wire length 192, and target `all`. The wasm and wasm-gc runs
use the same profile so parser, encoder, and stability properties are checked
against both WebAssembly backends in addition to the default target.

## Helper sharing boundaries

`cmd/fuzz-common` owns the pure helper logic shared by runnable harnesses:
deterministic RNG, TELNET-biased wire generation, parser configuration presets,
byte literals, byte slicing/concatenation, `ByteSpan` construction, and one-byte
chunk construction. `cmd/fuzz` and `cmd/fuzz-native` keep only thin wrappers or
harness-specific reproduction context around those helpers, which reduces drift
between deterministic extended fuzzing and native coverage-guided fuzzing.

`telnet_fuzz_test.mbt` intentionally keeps local copies of the small deterministic
helpers it needs. Those tests compile with the public TELNET package and must not
make the library package depend on command-only fuzz internals just to run the
fast default suite. The root tests also contain broader property-specific helper
families that are not useful to the runnable harnesses.

Observation normalization and failure formatting remain harness-local. The fast
suite needs detailed assertion summaries for named regression tests, `cmd/fuzz`
prints seed/iteration/max-length reproduction lines, and `cmd/fuzz-native` prints
stdin input length for external fuzzers. Keep those formats stable unless a new
fuzzer command or regression workflow requires an explicit change.

For a short reproducible local probe, pass explicit positional arguments after
`--`:

```sh
moon run cmd/fuzz -- 424242 1024 128 all
moon run cmd/fuzz -- 424242 256 128 streaming
```

The target must be one of `all`, `smoke`, `streaming`, or `stability`. The
runner prints the selected seed, iteration count, maximum length, target, and a
final checksum. A failing generated case prints a line shaped like:

```text
target=<target> seed=<seed> iteration=<n> max_length=<len> wire=bytes([...])
```

Copy the `wire=bytes([...])` literal into a named regression test before fixing
or documenting the issue.

## Optional native coverage-guided fuzzing

The native harness reads a single concrete TELNET wire input from stdin and
checks parser smoke, one-byte streaming equivalence, and parse/encode stability
properties. It is process-oriented rather than an in-process libFuzzer entry
point, so AFL++ stdin mode is the documented path for now.

Run the checked native validation helper for a fast local probe:

```sh
tools/check-fuzz-native.sh
```

The helper builds a non-instrumented binary, runs one tiny escaped-IAC stdin
input, then detects `afl-fuzz` and `afl-clang-fast`. When AFL++ is installed it
builds an instrumented binary and runs a bounded stdin-mode smoke session against
`tools/fuzz-corpus/seeds/`; when AFL++ is unavailable it reports the exact missing
tool and exits successfully unless `REQUIRE_AFL=1` is set. Tune the bounded AFL++
probe with `AFL_SMOKE_SECONDS`, `AFL_OUT`, `AFL_FUZZ`, `AFL_CC`,
`AFL_NATIVE_BIN`, and `FUZZ_SEED_DIR`.

Manual equivalent commands are:

```sh
tools/build-fuzz-native.sh
printf '\377\377' | _build/fuzz-native/telnet-fuzz-native

CC=afl-clang-fast tools/build-fuzz-native.sh _build/fuzz-native/telnet-fuzz-native-afl
afl-fuzz -V 5 -i tools/fuzz-corpus/seeds -o _build/fuzz-findings/native-smoke -- \
  _build/fuzz-native/telnet-fuzz-native-afl
```

Keep coverage-guided findings under `_build/` or another ignored directory. Do
not commit fuzzer output queues. Promote only minimized, named regression cases
or intentionally small seed files.

## Adding seeds and regressions

When fuzzing exposes a failure:

1. Save the full reproduction line in your notes while reducing the case.
2. Minimize the `wire=bytes([...])` array by deleting unrelated bytes while the
   same property still fails.
3. Add a named deterministic test in `telnet_fuzz_test.mbt`. Include the seed,
   iteration, target, and parser configuration in the test name, assertion
   message, or adjacent comment.
4. If the case is useful to coverage-guided mutation independently of the bug,
   add a tiny seed file under `tools/fuzz-corpus/seeds/` and document why it is
   representative. Prefer a short binary fixture over a long transcript.
5. Fix the bug when feasible. If behavior is intentional or deferred, document
   the limitation in the relevant wiki page and keep only a precise follow-up in
   `agent-todo.md`.

Seed corpus entries should be small, deterministic, and free of external trace
licensing ambiguity. If an imported trace is ever needed, record provenance and
license before committing it.

## Extending fuzz coverage

Prefer small, reviewable slices:

- add the deterministic regression first;
- keep generated loop bounds modest enough for normal `moon test` runs;
- put expensive exploration in `cmd/fuzz` or `cmd/fuzz-native` rather than in
  package tests;
- avoid adding public TELNET API solely for fuzzer internals; and
- update this page when a new property family, target, command, or reproduction
  format is added.
