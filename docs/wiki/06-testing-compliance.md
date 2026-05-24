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

The deterministic fuzz tests in `telnet_fuzz_test.mbt` keep default `moon test`
runs fast while covering parser smoke behavior, streaming equivalence, canonical
encode/parse stability, IAC escaping, subnegotiation boundaries, negotiation
state invariants, option/command catalog coverage, and NVT CR/LF/NUL handling.

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

Longer exploratory fuzzing should stay behind a separate command or explicit
configuration so the default test suite remains deterministic and quick.

## Minimum completion criteria for each option

- Source RFC linked in `04-options-catalog.md`.
- Encoder and parser behavior documented.
- Positive and negative tests.
- Unknown/unsupported peer behavior documented.
- Compatibility notes for any intentional deviation from strict RFC behavior.
