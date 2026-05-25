# 06 — Testing and Compliance

## Test layers

1. **Codec unit tests** — command constants, IAC escaping, chunk boundaries.
2. **Negotiation state tests** — RFC 1143 transitions and loop prevention.
3. **Option tests** — subnegotiation encoding/decoding for each supported option.
4. **Interop traces** — minimized byte transcripts from known clients/servers.
5. **Property/fuzz tests** — parser should never panic on arbitrary bytes.

## Fixture policy

- Prefer small handcrafted byte arrays derived from RFC examples.
- If importing external traces, record provenance and license in the fixture file.
- Keep expected parser events human-readable in test names or snapshots.

## Fuzzing notes

See [10-fuzzing.md](10-fuzzing.md) for the maintained fuzzing command guide,
property inventory, reproduction workflow, and seed-corpus rules.

The deterministic fuzz tests in `telnet_fuzz_test.mbt` keep default `moon test`
runs fast while covering parser smoke behavior, streaming equivalence, canonical
encode/parse stability, IAC escaping, subnegotiation boundaries, negotiation
state invariants, option/command catalog coverage, differential checks, performance
guardrails, and NVT CR/LF/NUL handling.

The core parser does not currently track negotiated BINARY session state. Fuzz
coverage therefore treats `CrPolicy::Preserve` as the binary-like parser mode:
CR, LF, NUL, and other mixed data bytes are preserved as data unless TELNET IAC
framing is present. NVT CR validation and LF normalization are opt-in parser
configurations covered by separate fuzz cases.

### Reproducing fuzz failures

Fuzz failures should print a compact reproduction line with the deterministic
seed and a `bytes([...])` wire literal. For generated cases, also capture the
iteration/case name from the failing test. Parser failures should include the
parser configuration, whether the mismatch came from whole-buffer parsing or a
chunked run, the chunk sizes or chunk seed when applicable, and the normalized
expected/observed events.

To promote a failure into a regression test:

1. Copy the printed `wire=bytes([...])` value into a named `fuzz_bytes_from_ints`
   or `bytes` fixture.
2. Preserve the reported seed and iteration in the test name, assertion message,
   or an adjacent comment.
3. Add the smallest deterministic assertion that reproduces the bug, usually a
   parser observation, streaming-equivalence, or parse/encode-stability check.
4. Fix the bug or document the remaining limitation, then keep the reduced test
   in the normal fast `moon test` suite.

Longer exploratory fuzzing lives in the separate `cmd/fuzz` package so the
default test suite remains deterministic and quick. Run the default extended
local pass with:

```sh
moon run cmd/fuzz
```

For CI, use the named bounded profile. It uses seed `20260524`, 4096 iterations,
maximum generated wire length 192, and target `all`:

```sh
moon run cmd/fuzz -- ci
moon run --target wasm cmd/fuzz -- ci
moon run --target wasm-gc cmd/fuzz -- ci
```

For a reproducible custom run, pass positional arguments after `--`:

```sh
moon run cmd/fuzz -- <seed> <iterations> <max-length> <target>
```

`<target>` is one of `all`, `smoke`, `streaming`, or `stability`. The command
prints the selected seed, iteration count, maximum generated wire length, target,
and a final checksum. On failure it prints `target=... seed=... iteration=...
max_length=... wire=bytes([...])` so the wire can be copied into a named
regression test. The GitHub Actions workflow in `.github/workflows/ci.yml` runs
`moon info`, `moon fmt --check`, `moon test`, target-parity tests, and the CI
fuzz profile on the default, wasm, and wasm-gc backends.

### Experimental native coverage-guided fuzzing

Feasibility decision: process-level coverage-guided fuzzing is practical for the
native target without changing the public TELNET API. The experimental
`cmd/fuzz-native` package reads one concrete TELNET wire input from stdin,
reuses the parser smoke, one-byte streaming-equivalence, and parse/encode
stability properties, and aborts with a `wire=bytes([...])` reproduction line on
failure. It is not part of default `moon test` or CI; use it only when a native
fuzzer is installed.

The current MoonBit CLI exposes enough native-build detail for an external
instrumenting C compiler workflow: `moon run --target native --build-only -v
cmd/fuzz-native` prints the generated C response file under `_build/native/`.
`tools/build-fuzz-native.sh` wraps that build and recompiles the generated C
entry point into `_build/fuzz-native/telnet-fuzz-native` with `CC` (or
`AFL_CC`), preserving the MoonBit runtime and TELNET native stubs. The script is
experimental because it depends on generated native artifact paths, but those
paths are isolated to optional fuzzing and are not needed for normal tests.

Example local AFL++ flow, using AFL++'s compiler wrapper and stdin fuzzing mode
(the AFL++ manual documents `afl-fuzz`, instrumentation, and `@@`/stdin input
styles at <https://aflplus.plus/docs/fuzzing_in_depth/>):

```sh
CC=afl-clang-fast tools/build-fuzz-native.sh
afl-fuzz -i tools/fuzz-corpus/seeds -o _build/fuzz-findings -- \
  _build/fuzz-native/telnet-fuzz-native
```

A quick non-instrumented harness smoke check is also useful before launching a
long run:

```sh
tools/build-fuzz-native.sh
printf '\377\377' | _build/fuzz-native/telnet-fuzz-native
```

libFuzzer is not the primary path for this slice: LLVM's libFuzzer interface is
centered on an in-process `LLVMFuzzerTestOneInput` entry point
(<https://llvm.org/docs/LibFuzzer.html>), while the current MoonBit harness is a
normal process with MoonBit runtime initialization and stdin input. honggfuzz can
drive process-style fuzz targets (<https://github.com/google/honggfuzz>), but a
file-path input mode or wrapper should be validated before documenting a stable
command. Keep any long coverage-guided campaign outside the repository; promote
failures into small named regression tests using the reproduction workflow above.

## Minimum completion criteria for each option

- Source RFC linked in `04-options-catalog.md`.
- Encoder and parser behavior documented.
- Positive and negative tests.
- Unknown/unsupported peer behavior documented.
- Compatibility notes for any intentional deviation from strict RFC behavior.
