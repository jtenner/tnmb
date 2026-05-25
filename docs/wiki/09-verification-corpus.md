# 09 — Verification Corpus

This page records the provenance and intended use of the executable TELNET test corpus.

## Primary specification sources

- [RFC 854 — Telnet Protocol Specification](https://www.rfc-editor.org/rfc/rfc854): command-byte table, IAC escaping, WILL/WON'T/DO/DON'T negotiation framing, and subnegotiation framing.
- [RFC 855 — Telnet Option Specifications](https://www.rfc-editor.org/rfc/rfc855): option design expectations and default behavior model.
- [RFC 1143 — Q Method of Implementing TELNET Option Negotiation](https://www.rfc-editor.org/rfc/rfc1143): loop-free negotiation state model used for negotiation tests.
- [IANA Telnet Options Registry](https://www.iana.org/assignments/telnet-options/telnet-options.xhtml): option number assignments used by known-option mapping tests.

## Option-specific specification sources

- [RFC 856 — Binary Transmission](https://www.rfc-editor.org/rfc/rfc856)
- [RFC 857 — Echo](https://www.rfc-editor.org/rfc/rfc857)
- [RFC 858 — Suppress Go Ahead](https://www.rfc-editor.org/rfc/rfc858)
- [RFC 885 — End of Record](https://www.rfc-editor.org/rfc/rfc885)
- [RFC 1073 — NAWS](https://www.rfc-editor.org/rfc/rfc1073)
- [RFC 1091 — Terminal-Type](https://www.rfc-editor.org/rfc/rfc1091)
- [RFC 1184 — Linemode](https://www.rfc-editor.org/rfc/rfc1184)
- [RFC 1572 — New Environment](https://www.rfc-editor.org/rfc/rfc1572)
- [RFC 2066 — Charset](https://www.rfc-editor.org/rfc/rfc2066)
- [RFC 2946 — START_TLS](https://www.rfc-editor.org/rfc/rfc2946)

## Cross-library behavior sources consulted

The corpus mirrors categories commonly tested by mature TELNET libraries without copying large source text:

- CPython `telnetlib` tests: raw queue processing, IAC command handling, negotiation callback behavior, and EOF/error behavior.
- `telnetlib3` tests: stream reader/writer behavior, IAC escaping, subnegotiation, terminal-type, NAWS, and environment handling.
- `libtelnet` tests: RFC 1143 negotiation behavior, ZMP/private-option negotiation, IAC escaping, and subnegotiation event behavior.
- Go TELNET libraries: encoder/parser round-trip checks for IAC commands and option triplets.

## Current corpus shape

All retained tests are behavioral: they call parser, encoder, negotiator, mapping, span, or option-codec APIs directly. Fixture-only tests that only asserted values against themselves were removed.

Current coverage lives in:

1. `telnet_test.mbt`: command/option mappings, parser fixtures, chunk boundaries, encoder fixtures, option payload basics, and negotiator transitions.
2. `telnet_edge_cases_test.mbt`: parser framing edge cases, subnegotiation IAC placement, protocol errors, encoder capacity errors, option boundary values, codec roundtrips, negotiator refusal, and byte-span slicing.
3. `telnet_behavior_tdd_test.mbt`: core parser, encoder, negotiator, mapping, and option-codec behavior through public APIs.
4. `telnet_expanded_behavior_tdd_test.mbt`: split-point invariance, CR policies, data coalescing, strict/lenient recovery, queued negotiation states, encoder capacity formulas, malformed option codecs, and mapping-helper ranges.
5. `telnet_missing_behavior_tdd_test.mbt`: parser partial-state checkpoints, sliced input, finish idempotence, accounting, capacity boundaries, encoder method equivalence, negotiator metadata/non-mutation, option codec roundtrips, START_TLS transcript policy, and BINARY/session TODO fixtures.
6. `telnet_policy_blind_spots_tdd_test.mbt`: explicit policy metadata, decoded option derivation, BINARY vs NVT behavior, output queue planning, zero-copy expectations, UTF-8 rejection, IANA mapping samples, and local request transition semantics.
7. `telnet_fuzz_test.mbt`: deterministic fuzz/property checks for parser, encoder, codecs, and negotiator invariants.
8. `telnet_wbtest.mbt`: whitebox tests for internal implementation details.

## Regression guard

`tools/check-test-tautologies.sh` runs in CI and rejects obvious no-op assertions such as `assert_true(x == x)` plus stale comments that indicate fixture-only tests.
