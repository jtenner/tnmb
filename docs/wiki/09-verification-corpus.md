# 09 — Verification Corpus

This page records the provenance and intended use of the executable TELNET test corpus.

## Primary specification sources

- [RFC 854 — Telnet Protocol Specification](https://www.rfc-editor.org/rfc/rfc854): command-byte table, IAC escaping, WILL/WON'T/DO/DON'T negotiation framing, and subnegotiation framing.
- [RFC 855 — Telnet Option Specifications](https://www.rfc-editor.org/rfc/rfc855): option design expectations and default behavior model.
- [RFC 1143 — Q Method of Implementing TELNET Option Negotiation](https://www.rfc-editor.org/rfc/rfc1143): loop-free negotiation state model used for negotiation tests.
- [IANA Telnet Options Registry](https://www.iana.org/assignments/telnet-options/telnet-options.xhtml): option number assignments used by known-option mapping tests. Re-verified on 2026-05-25 against the registry page last updated 2022-03-16: options `0..49` and `255` are modeled, `50..137` and `141..254` are unassigned, and assigned values `138..140` are preserved as lossless `Unknown` until the public enum is intentionally extended.

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
5. `telnet_missing_behavior_tdd_test.mbt`: parser partial-state checkpoints, sliced input, finish idempotence, accounting, capacity boundaries, exhaustive simple-command encoder acceptance/rejection atomicity, encoder method equivalence, negotiator metadata/non-mutation, option codec roundtrips, START_TLS transcript policy, and BINARY/session TODO fixtures.
6. `telnet_policy_blind_spots_tdd_test.mbt`: explicit policy metadata, decoded option derivation, BINARY vs NVT behavior, output queue planning, zero-copy expectations, UTF-8 rejection, IANA mapping samples, and local request transition semantics.
7. `telnet_restored_history_test.mbt`: useful regressions restored from removed fixture history, implemented against production APIs for login/MUD/NAWS/TTYPE transcripts, parser recovery, NVT CR split behavior, CHARSET TTABLE decoding, malformed option payloads, and encoder sizing matrices.
8. `telnet_restored_generated_history_test.mbt`: restored generated/matrix coverage converted from removed no-op cases into production API assertions for command bytes, parser command events, encoder command bytes, invalid IAC recovery, known/unknown option mappings, broad WILL option parsing, selected negotiation encodings, raw subnegotiation preservation, NAWS boundaries, LINEMODE flags, CHARSET TTABLE messages, and START_TLS codec roundtrips.
9. `telnet_restored_matrix_history_test.mbt`: restored the broad deleted matrix as real production tests for all 256 option-code conversions, every strict invalid IAC byte `0..239`, representative chunk split points, and the terminal-resize NAWS transcript.
10. `telnet_restored_negotiation_matrix_test.mbt`: restored RFC1143/Q-method matrix intent as exact production negotiator assertions for receive and local-request transitions across half-states, verbs, and decisions.
11. `telnet_restored_hardening_history_test.mbt`: restored hostile transcript and encoder hardening scenarios as real assertions for atomic command rejection, negotiation storms, endless/oversized subnegotiations, alternating invalid IAC bytes, and START_TLS refusal parsing.
12. `telnet_capacity_roundtrip_test.mbt`: exact-capacity, short-buffer, and padded-buffer encoder guardrails for `EncodeItem` and option payload encoders.
13. `telnet_lenient_matrix_test.mbt`: lenient invalid-IAC recovery matrix that asserts precise errors and resumed parsing.
14. `telnet_option_codec_roundtrip_matrix_test.mbt`: encode/decode roundtrip matrices for TERMINAL-TYPE, NAWS, NEW-ENVIRON, CHARSET, LINEMODE, and START_TLS payloads.
15. `telnet_subnegotiation_recovery_matrix_test.mbt`: malformed subnegotiation recovery matrix covering embedded TELNET commands, oversized discard, split-boundary overflow around `max_subnegotiation_bytes`, escaped-IAC overflow, and resumed parsing.
16. `telnet_finish_span_target_test.mbt`: finish/post-finish semantics, safe `ByteSpan::new` use with `feed_span`, zero-copy span expectations, and large scan target-parity guardrails.
17. `telnet_malformed_codec_matrix_test.mbt`: negative option-codec matrices for malformed TERMINAL-TYPE, NAWS, NEW-ENVIRON, CHARSET, LINEMODE, and START_TLS payloads, including ASCII/high-byte boundary metadata and current empty-field characterization for string-bearing codecs.
18. `telnet_parser_policy_matrix_test.mbt`: parser policy matrices for CR validation/normalization/preservation, zero data capacity, coalescing capacity, and partial checkpoint modes.
19. `telnet_encoder_edge_matrix_test.mbt`: encoder edge matrices for canonical RawData behavior, invalid span rejection, assume-capacity failures, wrong-`required` characterization, and negotiation verb helpers.
20. `telnet_encode_parse_roundtrip_matrix_test.mbt`: encoder-to-parser roundtrip matrices for simple commands, negotiation frames, escaped data, and representative subnegotiations.
21. `telnet_restore_semantics_test.mbt`: parser checkpoint/restore characterization, including resumable modes and non-restored buffered bytes.
22. `telnet_session_boundary_characterization_test.mbt`: current no-Session boundary tests for BINARY CR policy, START_TLS security handoff, decoded SB derivation, and raw unsupported payloads.
23. `telnet_iana_registry_characterization_test.mbt`: IANA registry characterization for mapped values, newer assigned-but-unmodeled values, and lossless unknown preservation.
24. `telnet_canonicalization_contract_test.mbt`: decode-tolerant/encode-canonical behavior for CHARSET, LINEMODE, and raw payloads.
25. `telnet_rawdata_invalid_span_contract_test.mbt`: RawData and safe invalid-span contract characterization.
26. `telnet_docs_examples_test.mbt`: executable user-facing API examples for parsing, encoding, and NAWS decoding.
27. `telnet_more_docs_examples_test.mbt`: additional docs-style examples for streaming parsing, carried parser state across split negotiations, negotiation policy flow with encoded reply actions, TTYPE encoding/decoding, environment decoding, START_TLS decode with external transport enforcement, canonical data escaping, incomplete-input finish handling, and unknown-option rejection.
28. `telnet_interop_transcript_corpus_test.mbt`: small interop-inspired transcript corpus for BSD/telnetlib-like negotiation, MUD/private options, TTYPE cycling, NAWS resize streams, EOR/STATUS/X-DISPLAY-LOCATION/NEW-ENVIRON/AUTHENTICATION/ENCRYPTION/KERMIT/SEND-URL/FORWARD-X transcripts, and escaped IAC data.
29. `telnet_native_scanner_stress_test.mbt`: scanner stress tests that exercise no-IAC fast paths, nonzero-start public `feed_span` edge cases, adjacent slices from the same backing buffer, dense IAC runs, separate-feed IAC recovery, and long subnegotiation scans on JS and native targets.
30. `telnet_differential_reference_test.mbt`: compact differential reference parser checks for complete TELNET command/negotiation streams.
31. `telnet_rfc1143_loop_characterization_test.mbt`: RFC1143 loop-prevention characterization for duplicate/refusal negotiation inputs and pending requests.
32. `telnet_unknown_raw_payload_matrix_test.mbt`: raw payload preservation matrix for private/newer/unknown TELNET options.
33. `telnet_iac_boundary_matrix_test.mbt`: IAC streaming boundary matrix for escaped data, commands, negotiations, subnegotiations, and dangling finish errors.
34. `telnet_option_mapping_registry_samples_test.mbt`: exhaustive modeled `KnownOption` IANA registry mapping tests for codes `0..49` and `255`, plus unmodeled assigned-value preservation for `138..140`.
35. `telnet_rfc1143_normative_characterization_test.mbt`: current negotiator characterization against RFC1143/Q-method edge areas, including apply independence, pending replies, duplicate commands, queued opposites, and documented normative gaps.
36. `telnet_public_invalid_span_safety_test.mbt`: safe public-API characterization for raw invalid `ByteSpan` values, plus constructor-clamping expectations.
37. `telnet_complexity_guardrail_test.mbt`: deterministic complexity guardrails for large data, dense IAC streams, negotiation storms, oversized subnegotiations, and command storms.
38. `telnet_differential_subnegotiation_test.mbt`: independent complete-stream reference parser checks for subnegotiation transcripts and generated escaped-payload cases.
39. `telnet_fuzz_test.mbt`: deterministic fuzz/property checks for parser, encoder, codecs, and negotiator invariants.
40. `telnet_wbtest.mbt`: whitebox tests for internal implementation details.
41. `telnet_feed_span_into_contract_test.mbt`: public `Parser::feed_span_into` reuse contract coverage for caller-owned event buffer clearing, stale-event exclusion, split-stream equivalence with `feed_span`, byte accounting, checkpoint parity, and incomplete-input completion.
42. `telnet_cr_policy_split_matrix_test.mbt`: all-split CR policy matrix for CR NUL, CR LF, CR-before-data, bare CR finish, CR before commands/escaped IAC/negotiation, and CR around or inside subnegotiation framing.
43. `telnet_negotiator_sequence_characterization_test.mbt`: stateful negotiator sequence characterization for request/accept/refuse flows, queued opposite requests, simultaneous local/remote enables, duplicate command storms, non-mutating transitions, bounded sends, and option independence.
44. `telnet_invalid_command_split_matrix_test.mbt`: strict and lenient invalid-IAC split-boundary characterization for dangling IAC recovery, surrounding data, valid-command recovery, escaped-IAC data, subnegotiation-after-IAC recovery, and negotiation triplets.
45. `telnet_bytespan_ownership_characterization_test.mbt`: public parser-output `ByteSpan` ownership characterization for borrowed no-IAC fast-path spans, copied chunked/buffered data, normalized CR output, and copied subnegotiation payloads.
46. `telnet_named_fuzz_seed_regression_test.mbt`: named deterministic fuzz-seed regressions that manually assert dense escaped-IAC streams, nested-looking SB recovery, invalid-command recovery, CR split policy behavior, mixed negotiation/SB/data ordering, oversized-SB recovery, and unknown/private raw SB preservation through parser, codec, and encoder APIs.
47. `telnet_target_parity_codec_encoder_test.mbt`: target-parity codec/encoder fixtures for NAWS min/max words, unknown raw high-byte payloads, ASCII boundary strings, and large `Bytes::make` raw/escaped payloads across wasm/js/native.

Additional non-executable plans live in `docs/wiki/test-plan-negotiator-session.md` for RFC1143 normative gaps, unsafe raw-span panic shapes, and future session-level behavior.

## Regression guard

`tools/check-test-tautologies.sh` runs in CI and rejects obvious no-op assertions such as `assert_true(x == x)` plus stale comments that indicate fixture-only tests.
