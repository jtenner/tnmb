# Negotiator, session, and raw-span characterization plan

This file records meaningful gaps that are not added as failing tests because the current task is test-only and must not change production behavior.

## RFC 1143 Q-method negotiator gaps

The current public `Negotiator` exposes `WantNo`/`WantYes`/`QueueBit`, but the receive path is a simplified transition model rather than the full RFC 1143 switch table. Passing characterization coverage lives in:

- `telnet_rfc1143_loop_characterization_test.mbt`
- `telnet_rfc1143_normative_characterization_test.mbt`
- `telnet_restored_negotiation_matrix_test.mbt`

Normative expectations to promote only with an approved production change:

1. Duplicate `DONT` for an already disabled local half should be a no-op, not an emitted `WONT` reply.
2. A positive reply to a pending local/remote enable request should generally settle the Q state without a duplicate affirmative reply.
3. `WantNo` states with queued opposite requests need the full RFC 1143 handling: settle the refusal/disable and then send the queued enable where appropriate.
4. `WantYes(Opposite)` should complete enable and immediately send the queued disable where appropriate.
5. Receive transitions should preserve no-loop guarantees under simultaneous enable/disable request races across both local and remote halves.

## Raw invalid `ByteSpan` gaps

`ByteSpan` fields are public, so callers can construct spans that bypass `ByteSpan::new`. Passing safety characterization lives in:

- `telnet_rawdata_invalid_span_contract_test.mbt`
- `telnet_public_invalid_span_safety_test.mbt`

APIs that currently have safe rejection paths for invalid raw spans include `Encoder::encode_data`, `EncodeItem::EscapedData` through `encode_item`, and `OptionPayload::Raw` through `OptionPayload::encode`.

Do not add executable panic tests unless the MoonBit harness gains expected-panic support. Unsafe shapes to cover after an API-hardening change include:

1. `Parser::feed_span` with a non-empty raw span whose range is outside the backing `Bytes`.
2. `Encoder::encode_subnegotiation` with a non-empty invalid payload span.
3. `OptionPayload::Linemode(ForwardMask(Bytes(...)))` or `Slc(...)` with enough output capacity and an invalid non-empty span.
4. Direct codec `decode` calls with invalid non-empty spans for codecs that index before validating the raw range.

## Encoder assume-capacity contract gaps

Passing characterization for safe wrong-`required` values lives in `telnet_encoder_edge_matrix_test.mbt`. The current `Encoder::encode_data_assume_capacity` and `Encoder::encode_subnegotiation_assume_capacity` methods trust `required` for the output-size precheck and for the returned `EncodeResult`, but write the actual encoded bytes. Safe tests therefore use an output buffer large enough for the actual encoded shape when `required` is too small.

Normative expectations to promote only with an approved production change:

1. `required` should either be validated against the actual encoded size or the API contract should explicitly require callers to pass the exact precomputed capacity.
2. Too-small `required` with an output buffer whose length equals `required` can panic or write beyond the intended caller-reserved region; keep this as a documented gap instead of an executable panic test.
3. Too-large `required` currently reports the inflated value and leaves trailing output bytes unchanged; decide whether that should remain a documented low-level contract or become a validation error.

## Future session-level tests

The core intentionally has no public `Session` type today. Current boundary characterization lives in `telnet_session_boundary_characterization_test.mbt` and proves that parser/codec policy is external.

Promote these scenarios if/when a `Session` abstraction is approved:

1. Directional BINARY negotiation changes CR/NUL handling only for the negotiated data direction.
2. `START_TLS FOLLOWS` blocks plaintext until a transport-upgrade callback succeeds.
3. Policy callbacks decide option acceptance and receive decoded payloads without coupling to the raw parser.
4. A session-level event stream can combine raw parser events, decoded option-payload events, negotiation actions, and transport-security state transitions.
