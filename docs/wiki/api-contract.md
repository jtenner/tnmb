# API Contract Skeleton

The public API skeleton lives in `api.mbt`. Function bodies intentionally use MoonBit `...` placeholders so the package exposes the intended signatures before production behavior is implemented.

## Parser

The parser is transport-independent and incremental.

- `Parser::default_config() -> ParserConfig`
- `Parser::new(ParserConfig) -> Parser`
- `Parser::default() -> Parser`
- `Parser::feed(Parser, Bytes) -> ParserFeedResult`
- `Parser::feed_span(Parser, ByteSpan) -> ParserFeedResult`
- `Parser::finish(Parser) -> ParserFinishResult`
- `Parser::checkpoint(Parser) -> ParserCheckpoint`
- `Parser::restore(ParserConfig, ParserCheckpoint) -> Parser`
- `Parser::reset(Parser) -> Parser`
- `Parser::with_config(Parser, ParserConfig) -> Parser`

Expected behavior:

- Consume arbitrary byte chunks.
- Preserve parser state across chunk boundaries.
- Emit TELNET events without owning a network transport.
- Report incomplete sequences on `finish`.
- Honor `ParserConfig` for CR policy, strictness, coalescing, and size limits.

## Encoder

The encoder writes canonical TELNET wire bytes.

- `Encoder::new() -> Encoder`
- `Encoder::canonical() -> Encoder`
- `Encoder::required_capacity(Encoder, EncodeItem) -> Int`
- `Encoder::encode_item(Encoder, EncodeItem, Bytes) -> Result[EncodeResult, EncodeError]`
- `Encoder::encode_data(Encoder, ByteSpan, Bytes) -> Result[EncodeResult, EncodeError]`
- `Encoder::encode_command(Encoder, Command, Bytes) -> Result[EncodeResult, EncodeError]`
- `Encoder::encode_negotiation(Encoder, NegotiationEvent, Bytes) -> Result[EncodeResult, EncodeError]`
- `Encoder::encode_subnegotiation(Encoder, SubnegotiationEvent, Bytes) -> Result[EncodeResult, EncodeError]`

Expected behavior:

- Escape data byte `0xFF` as `IAC IAC`.
- Encode commands as `IAC <command>`.
- Encode negotiation as `IAC WILL/WON'T/DO/DON'T <option>`.
- Encode subnegotiation as `IAC SB <option> ... IAC SE` with payload IAC escaping.
- Fail atomically when output capacity is insufficient.

## Negotiator

The negotiator implements RFC 1143 Q-method state transitions.

- `Negotiator::new() -> Negotiator`
- `Negotiator::with_states(Array[OptionState]) -> Negotiator`
- `Negotiator::receive(Negotiator, NegotiationEvent, PolicyDecision) -> NegotiationTransition`
- `Negotiator::request(Negotiator, OptionCode, OptionSide, Bool) -> NegotiationTransition`
- `Negotiator::state_for(Negotiator, OptionCode) -> OptionState`
- `Negotiator::apply(Negotiator, NegotiationTransition) -> Negotiator`

Expected behavior:

- Track local and remote option halves independently.
- Avoid WILL/WON'T/DO/DON'T loops.
- Support queued opposite requests.
- Emit explicit actions for protocol responses and application notifications.

## Protocol mapping helpers

- `Command::from_byte(Byte) -> Command?`
- `Command::to_byte(Command) -> Byte`
- `NegotiationVerb::from_command(Command) -> NegotiationVerb?`
- `NegotiationVerb::to_command(NegotiationVerb) -> Command`
- `OptionCode::new(Byte) -> OptionCode`
- `OptionCode::to_byte(OptionCode) -> Byte`
- `KnownOption::from_code(OptionCode) -> KnownOption`
- `KnownOption::to_code(KnownOption) -> OptionCode`
- `ByteSpan::new(Bytes, Int, Int) -> ByteSpan`
- `ByteSpan::is_empty(ByteSpan) -> Bool`
- `ByteSpan::to_bytes(ByteSpan) -> Bytes`

## Option payload codecs

- `OptionPayload::decode(OptionCode, ByteSpan) -> Result[OptionPayload, TelnetError]`
- `OptionPayload::encode(OptionPayload, Bytes) -> Result[EncodeResult, EncodeError]`
- `OptionPayload::required_capacity(OptionPayload) -> Int`

Specific codec namespaces:

- `TerminalTypeMessage::decode/encode`
- `NawsSize::decode/encode`
- `EnvironmentMessage::decode/encode`
- `CharsetMessage::decode/encode`
- `LinemodeMessage::decode/encode`
- `StartTlsMessage::decode/encode`

## Placeholder policy

All placeholder bodies must be replaced before release. Until then, `moon check` warns about unfinished code and `moon test` is expected to fail because `telnet_behavior_tdd_test.mbt` calls these APIs directly. This is intentional TDD pressure: the API is visible in the generated interface, and the behavioral tests describe the production work still required.
