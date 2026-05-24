# 09 — Verification Corpus

This page records the provenance and intended use of the initial test corpus in `telnet_test.mbt`.

## Primary specification sources

- [RFC 854 — Telnet Protocol Specification](https://www.rfc-editor.org/rfc/rfc854): command-byte table, IAC escaping, WILL/WON'T/DO/DON'T negotiation framing, and subnegotiation framing.
- [RFC 855 — Telnet Option Specifications](https://www.rfc-editor.org/rfc/rfc855): option design expectations and default behavior model.
- [RFC 1143 — Q Method of Implementing TELNET Option Negotiation](https://www.rfc-editor.org/rfc/rfc1143): loop-free negotiation state model used for the negotiation fixture matrix.
- [IANA Telnet Options Registry](https://www.iana.org/assignments/telnet-options/telnet-options.xhtml): option number assignments used by the known-option fixture table.

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

The initial corpus intentionally mirrors categories commonly tested by mature TELNET libraries without copying large source text:

- CPython `telnetlib` tests: raw queue processing, IAC command handling, negotiation callback behavior, and EOF/error behavior.
- `telnetlib3` tests: stream reader/writer behavior, IAC escaping, subnegotiation, terminal-type, NAWS, and environment handling.
- `libtelnet` tests: RFC 1143 negotiation behavior, ZMP/private-option negotiation, IAC escaping, and subnegotiation event behavior.
- Go TELNET libraries: encoder/parser round-trip checks for IAC commands and option triplets.

## Current corpus shape

`telnet_test.mbt` currently contains fixture-first tests for:

1. RFC 854 command byte assignments.
2. IANA/common option assignments.
3. Ordinary data and every simple IAC command.
4. WILL/WON'T/DO/DON'T negotiation triplets.
5. Subnegotiation framing and payload IAC escaping.
6. Incomplete parser states at finalization.
7. Chunk-boundary splits across each parser mode.
8. Encoder expectations for data escaping, commands, negotiation, and subnegotiation.
9. NVT CR policy configuration variants.
10. Buffer ownership/copy-behavior fixtures for future zero-copy APIs.
11. Option payload fixtures for TERMINAL-TYPE, NAWS, NEW-ENVIRON, CHARSET, LINEMODE, and START_TLS.
12. RFC 1143 Q-method transition matrices for WILL, WON'T, DO, and DON'T.
13. A libtelnet-inspired private-option/ZMP negotiation fixture.
14. Edge cases for repeated IAC bytes, command/data ordering, escaped IAC bytes inside subnegotiation, malformed subnegotiation commands, buffer-capacity errors, zero-copy spans, unknown/private options, invalid option payload shapes, and independent local/remote Q-method halves.
15. Comprehensive matrix fixtures for every option code, representative invalid `IAC` commands, every split point in representative streams, NVT CR policies, binary-mode invariants, data-coalescing policies, negotiation initiation, full RFC 1143 half-state/verb/decision combinations, option validation, round-trip pairs, and hardening inputs.

## Important limitation

Because production parser/encoder/negotiator functions have not been implemented yet, the first version of the tests is an executable fixture corpus. As production APIs are added, each fixture group should be converted from self-checking expected data into real behavior assertions against the implementation.
