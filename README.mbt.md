# jtenner/telnet

Transport-independent TELNET protocol core for MoonBit.

This package parses and emits TELNET byte streams, models TELNET commands and
option negotiation, and provides codecs for common subnegotiation payloads. It is
intended to sit below your TCP/TLS/runtime code and above application policy.

## Status

The core parser, encoder, option mapper, option-payload codecs, and negotiation
state APIs are implemented and covered by a broad behavioral test corpus. The
library deliberately does **not** provide a public `Session` abstraction yet:
transport I/O, TLS handoff, credential handling, terminal rendering, and option
acceptance policy remain application responsibilities.

## Features

- Incremental TELNET parser for arbitrary byte chunks.
- TELNET encoder for data, commands, negotiation triplets, and subnegotiations.
- Canonical IAC escaping for data and subnegotiation payloads.
- WILL/WON'T/DO/DON'T negotiation state with explicit transition actions.
- RFC/IANA command and option mapping helpers.
- Option-payload codecs for:
  - BINARY policy boundary
  - ECHO and SUPPRESS-GO-AHEAD negotiation
  - TERMINAL-TYPE
  - NAWS
  - LINEMODE
  - NEW-ENVIRON
  - CHARSET
  - START_TLS as a transport-security boundary codec
- Lossless raw preservation for unknown/private option payloads.
- Deterministic fuzz/property tests, target-parity checks, and native scanner
  stress coverage.

## Non-goals

- No TCP or async runtime dependency in the core package.
- No built-in remote shell server.
- No automatic credential handling.
- No terminal emulator.
- No bundled TLS implementation; START_TLS enforcement belongs to an adapter or
  future session layer.

## Quick examples

### Parse a stream

```moonbit nocheck
let parser = @telnet.Parser::default()
let result = parser.feed(Bytes::from_array([
  72.to_byte(), 105.to_byte(), 255.to_byte(), 246.to_byte(),
]))
// Events: Data("Hi"), Command(AYT)
```

For streaming input, keep the returned parser and feed the next chunk:

```moonbit nocheck
let first = @telnet.Parser::default().feed(Bytes::from_array([
  255.to_byte(), 251.to_byte(),
]))
let second = first.parser.feed(Bytes::from_array([1.to_byte()]))
// Event: Negotiation(WILL, ECHO)
```

### Encode TELNET bytes

```moonbit nocheck
let out = Bytes::new(3)
let event = @telnet.NegotiationEvent::{
  verb: @telnet.NegotiationVerb::Will,
  option: @telnet.OptionCode::new(1.to_byte()), // ECHO
}
let item = @telnet.EncodeItem::Negotiation(event)
ignore(@telnet.Encoder::canonical().encode_item(item, out))
// out == IAC WILL ECHO: [255, 251, 1]
```

Canonical data encoding doubles IAC bytes:

```moonbit nocheck
let data = @telnet.ByteSpan::new(
  Bytes::from_array([65.to_byte(), 255.to_byte(), 66.to_byte()]),
  0,
  3,
)
let out = Bytes::new(4)
ignore(@telnet.Encoder::canonical().encode_item(
  @telnet.EncodeItem::EscapedData(data),
  out,
))
// out == [65, 255, 255, 66]
```

### Decode subnegotiation payloads

```moonbit nocheck
let payload = @telnet.ByteSpan::new(
  Bytes::from_array([0.to_byte(), 80.to_byte(), 0.to_byte(), 24.to_byte()]),
  0,
  4,
)
match @telnet.OptionPayload::decode(@telnet.OptionCode::new(31.to_byte()), payload) {
  Ok(@telnet.OptionPayload::Naws(size)) => {
    // size.columns == 80, size.rows == 24
  }
  _ => ()
}
```

### Drive option negotiation

```moonbit nocheck
let negotiator = @telnet.Negotiator::new()
let incoming = @telnet.NegotiationEvent::{
  verb: @telnet.NegotiationVerb::Will,
  option: @telnet.OptionCode::new(1.to_byte()), // ECHO
}
let transition = negotiator.receive(incoming, @telnet.PolicyDecision::Accept)
let updated = negotiator.apply(transition)
// Encode any NegotiationAction::Send replies and write them on your transport.
```

## Main API areas

- `Parser`: incremental byte-stream parser with `feed`, `feed_span`, `finish`,
  checkpoints, restore/reset, and configurable CR/coalescing/strictness policy.
- `Encoder`: canonical and raw TELNET byte encoders with capacity reporting.
- `Negotiator`: local/remote option-half state and explicit transition actions.
- `OptionPayload`: decode/encode helpers for supported subnegotiation payloads.
- `ByteSpan`: public byte-slice model used by parser events and encoders.
- Mapping helpers: `Command`, `NegotiationVerb`, `OptionCode`, and `KnownOption`.

## Policy boundaries

The parser reports protocol events; it does not make application security or
session decisions.

- `CrPolicy` controls NVT CR/LF/CR-NUL handling at parser construction time.
- BINARY negotiation is visible through negotiation state; it does not silently
  mutate parser configuration.
- `START_TLS FOLLOWS` decodes as a payload, but plaintext blocking and transport
  upgrade enforcement are application/session responsibilities.
- Unknown or unsupported option payloads can be preserved as `OptionPayload::Raw`.

Known future/session-level design notes live in
[`docs/wiki/test-plan-negotiator-session.md`](docs/wiki/test-plan-negotiator-session.md).

## Supported options

| Code | Name | Notes |
|---:|---|---|
| 0 | BINARY | Negotiation/policy boundary; core parser exposes bytes. |
| 1 | ECHO | Negotiation support. |
| 3 | SUPPRESS-GO-AHEAD | Negotiation support. |
| 24 | TERMINAL-TYPE | `SEND`/`IS` payload codec. |
| 25 | END-OF-RECORD | Command/option mapping support. |
| 31 | NAWS | Width/height payload codec. |
| 34 | LINEMODE | Mode, SLC, and forward-mask payload codec. |
| 39 | NEW-ENVIRON | `IS`/`SEND`/`INFO` variable payload codec. |
| 42 | CHARSET | Request/accept/reject and TTABLE payload codec. |
| 46 | START_TLS | Payload codec; transport security is external. |

The full option source of truth is
[`docs/wiki/04-options-catalog.md`](docs/wiki/04-options-catalog.md). IANA
registry characterization is tracked in the executable tests and
[`docs/wiki/09-verification-corpus.md`](docs/wiki/09-verification-corpus.md).

## Testing

Normal validation:

```sh
moon info
moon fmt
moon test
```

Target-parity validation:

```sh
moon test --target js
moon test --target native
```

Deterministic fuzz profile:

```sh
moon run cmd/fuzz -- ci
moon run --target wasm cmd/fuzz -- ci
moon run --target wasm-gc cmd/fuzz -- ci
```

Additional guards:

```sh
bash tools/check-test-tautologies.sh
git diff --check
```

At the time this README was updated, `moon coverage analyze` reported no
uncovered lines in the core `api.mbt`; remaining uncovered lines were in command
harnesses under `cmd/`.

## Benchmarks

A runnable benchmark package lives in [`cmd/bench`](cmd/bench). It supports
JavaScript timing via `performance.now()`, native timing via a small
monotonic-clock C stub, and WebAssembly timing through a tiny JavaScript host
runner:

```sh
moon run --target js cmd/bench
moon run --target native cmd/bench

moon build --target wasm cmd/bench
node tools/run-wasm-bench.mjs _build/wasm/debug/build/cmd/bench/bench.wasm

moon build --target wasm-gc cmd/bench
bun tools/run-wasm-bench.mjs _build/wasm-gc/debug/build/cmd/bench/bench.wasm
```

The runner reports elapsed milliseconds, operations/second, approximate MB/s for
byte-oriented workloads, and a checksum for each benchmark.

Before publishing performance numbers, collect repeated runs and average every
benchmark row:

```sh
node tools/collect-benchmarks.mjs --runs 5 \
  --markdown _build/bench/report.md \
  --out _build/bench/report.json
```

Use `--targets js-node,js-bun,native,wasm-node,wasm-bun,wasm-gc-bun` to select a
subset, `--no-build` to reuse existing artifacts, and `--strict` to fail instead
of skipping unavailable runtimes such as Bun.

Local benchmark baselines should be refreshed when performance-sensitive parser,
encoder, or negotiator code changes. This table is intentionally compact; keep
full command output in release notes or PR logs when a detailed comparison is
needed.

| Date | Machine / runtime | Target | Representative local results |
|---|---|---:|---|
| 2026-05-25 | AMD Ryzen 7 8845HS, Node v20.19.2 | js | `parser_plain_1m_8192_chunks`: 611 MB/s; `parser_iac_escaped_sparse`: 171 MB/s; `encoder_raw_1m_assume_capacity`: 327 MB/s; `e2e_interactive_shell`: 6,170 ops/s. |
| 2026-05-25 | AMD Ryzen 7 8845HS, Bun 1.3.13 | js | `parser_plain_1m_8192_chunks`: 1,645 MB/s; `parser_iac_escaped_sparse`: 428 MB/s; `encoder_raw_1m_assume_capacity`: 1,134 MB/s; `e2e_interactive_shell`: 9,083 ops/s. |
| 2026-05-25 | AMD Ryzen 7 8845HS, Moon native | native | `parser_plain_1m_8192_chunks`: 21,531 MB/s; `parser_iac_escaped_sparse`: 178 MB/s; `encoder_raw_1m_assume_capacity`: 441 MB/s; `e2e_interactive_shell`: 2,596 ops/s. |
| 2026-05-25 | AMD Ryzen 7 8845HS, Node v20.19.2 | wasm | `parser_plain_1m_8192_chunks`: 864 MB/s; `parser_iac_escaped_sparse`: 97 MB/s; `encoder_raw_1m_assume_capacity`: 713 MB/s; `e2e_interactive_shell`: 3,061 ops/s. |
| 2026-05-25 | AMD Ryzen 7 8845HS, Bun 1.3.13 | wasm | `parser_plain_1m_8192_chunks`: 1,658 MB/s; `parser_iac_escaped_sparse`: 193 MB/s; `encoder_raw_1m_assume_capacity`: 774 MB/s; `e2e_interactive_shell`: 4,280 ops/s. |
| 2026-05-25 | AMD Ryzen 7 8845HS, Bun 1.3.13 | wasm-gc | `parser_plain_1m_8192_chunks`: 2,030 MB/s; `parser_iac_escaped_sparse`: 675 MB/s; `encoder_raw_1m_assume_capacity`: 2,035 MB/s; `e2e_interactive_shell`: 10,711 ops/s. |

Note: this local Node v20.19.2 runtime could run the wasm build but could not
instantiate the wasm-gc build; the wasm-gc row above was measured with Bun
1.3.13.

## Documentation

Start with [`docs/wiki/README.md`](docs/wiki/README.md). Useful pages include:

- [`docs/wiki/00-sources.md`](docs/wiki/00-sources.md) — RFC/IANA source policy.
- [`docs/wiki/02-protocol-model.md`](docs/wiki/02-protocol-model.md) — parser
  event model and TELNET byte stream notes.
- [`docs/wiki/03-option-negotiation.md`](docs/wiki/03-option-negotiation.md) —
  negotiation model.
- [`docs/wiki/04-options-catalog.md`](docs/wiki/04-options-catalog.md) — option
  support matrix.
- [`docs/wiki/06-testing-compliance.md`](docs/wiki/06-testing-compliance.md) —
  test and fuzz strategy.
- [`docs/wiki/conformance-matrix.md`](docs/wiki/conformance-matrix.md) —
  requirement-to-test traceability.

Protocol claims should be backed by RFC Editor, IETF Datatracker, or IANA
registry links in the wiki.

## License

MIT. See [`LICENSE`](LICENSE).
