// Policy/API blind-spot behavioral tests.
// These lock down decisions that would otherwise cause churn in parser,
// encoder, negotiator, codec, and policy behavior.

///|
fn policy_config() -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
fn policy_error(
  kind : @telnet.TelnetErrorKind,
  offset : Int,
  byte_value : Int?,
  option : Int?,
) -> @telnet.Event {
  let b = match byte_value {
    Some(n) => Some(byte(n))
    None => None
  }
  let opt_value = match option {
    Some(n) => Some(opt(n))
    None => None
  }
  @telnet.Event::Error(@telnet.TelnetError::{
    kind,
    offset,
    byte: b,
    option: opt_value,
  })
}

///|
test "TDD low-level APIs can compose a minimal receive negotiation session" {
  let parser = @telnet.Parser::new(policy_config())
  let parsed = parser.feed(bytes([255, 251, 1]))
  assert_true(parsed.events == [neg(@telnet.NegotiationVerb::Will, 1)])
  let negotiator = @telnet.Negotiator::new()
  let transition = negotiator.receive(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Accept,
  )
  let applied = negotiator.apply(transition)
  assert_true(applied.state_for(opt(1)).remote_state == @telnet.HalfState::Yes)
  let output = Bytes::new(3)
  match
    @telnet.Encoder::canonical().encode_negotiation(
      neg_event(@telnet.NegotiationVerb::Do, 1),
      output,
    ) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(output == bytes([255, 253, 1]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD policy decision is explicit and transition metadata preserves it" {
  let negotiator = @telnet.Negotiator::new()
  let input = neg_event(@telnet.NegotiationVerb::Do, 37)
  let transition = negotiator.receive(input, @telnet.PolicyDecision::Reject)
  assert_true(transition.input == input)
  assert_true(transition.decision == @telnet.PolicyDecision::Reject)
  assert_true(transition.before.option == opt(37))
  assert_true(transition.after.option == opt(37))
  assert_true(
    transition.actions ==
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 37),
      ),
    ],
  )
}

///|
test "TDD application-facing decoded option events can be derived from raw SB" {
  let parser = @telnet.Parser::new(policy_config())
  let parsed = parser.feed(bytes([255, 250, 31, 0, 100, 0, 40, 255, 240]))
  assert_true(parsed.events == [sb(31, [0, 100, 0, 40])])
  match @telnet.OptionPayload::decode(opt(31), span([0, 100, 0, 40])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Naws(@telnet.NawsSize::{
          columns: (100).to_uint16(),
          rows: (40).to_uint16(),
        }),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD BINARY state leaves CR bytes raw while NVT mode validates CR" {
  let binary = @telnet.Negotiator::with_states([
    option_state(0, @telnet.HalfState::No, @telnet.HalfState::Yes),
  ])
  assert_true(binary.state_for(opt(0)).remote_state == @telnet.HalfState::Yes)
  let raw_parser = @telnet.Parser::new(policy_config())
  assert_true(raw_parser.feed(bytes([13, 88])).events == [data([13, 88])])
  let nvt_parser = @telnet.Parser::new(@telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::ValidateNvt,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  })
  assert_true(
    nvt_parser.feed(bytes([13, 88])).events ==
    [
      policy_error(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(88), None),
      data([88]),
    ],
  )
}

///|
test "TDD encoder EscapedData performs IAC escaping but not NVT newline canonicalization" {
  let output = Bytes::new(8)
  match
    @telnet.Encoder::canonical().encode_item(
      @telnet.EncodeItem::EscapedData(span([10, 13, 255])),
      output,
    ) {
    Ok(r) => {
      assert_true(r.bytes_written == 4)
      assert_true(output[0] == byte(10))
      assert_true(output[1] == byte(13))
      assert_true(output[2] == byte(255))
      assert_true(output[3] == byte(255))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD parser error metadata differentiates CR policy and option context" {
  let parser = @telnet.Parser::new(@telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::ValidateNvt,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  })
  let result = parser.feed(bytes([255, 250, 24, 1, 255, 241, 255, 240, 13, 88]))
  assert_true(
    result.events ==
    [
      policy_error(
        @telnet.TelnetErrorKind::InvalidCommandByte,
        5,
        Some(241),
        Some(24),
      ),
      sb(24, [1]),
      policy_error(@telnet.TelnetErrorKind::PolicyRejected, 9, Some(88), None),
      data([88]),
    ],
  )
}

///|
test "TDD ByteSpan invalid bounds clamp to empty safe spans" {
  let bs = bytes([65, 66, 67])
  let negative_start = @telnet.ByteSpan::new(bs, -1, 2)
  assert_true(negative_start.start == 0)
  assert_true(negative_start.length == 0)
  assert_true(negative_start.to_bytes() == bytes([]))
  let negative_length = @telnet.ByteSpan::new(bs, 1, -2)
  assert_true(negative_length.start == 1)
  assert_true(negative_length.length == 0)
  let overrun = @telnet.ByteSpan::new(bs, 2, 10)
  assert_true(overrun.start == 2)
  assert_true(overrun.length == 1)
}

///|
test "TDD Parser::new normalizes invalid capacity config to hardened zero limits" {
  let parser = @telnet.Parser::new(@telnet.ParserConfig::{
    max_data_chunk_bytes: -1,
    max_subnegotiation_bytes: -99,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCapacity,
    strict_commands: true,
  })
  assert_true(parser.config.max_data_chunk_bytes == 0)
  assert_true(parser.config.max_subnegotiation_bytes == 0)
  assert_true(
    parser.feed(bytes([65])).events ==
    [policy_error(@telnet.TelnetErrorKind::PolicyRejected, 0, Some(65), None)],
  )
}

///|
test "TDD encoder rejects invalid ByteSpan bounds atomically" {
  let invalid = @telnet.ByteSpan::new(bytes([65, 66]), 9, 3)
  let output = Bytes::make(4, byte(77))
  match @telnet.Encoder::canonical().encode_data(invalid, output) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
      assert_true(e.offset == 0)
      assert_true(output == bytes([77, 77, 77, 77]))
    }
  }
}

///|
test "TDD parser emits raw malformed option payload and codec rejects later" {
  let parser = @telnet.Parser::new(policy_config())
  let parsed = parser.feed(bytes([255, 250, 24, 9, 255, 240]))
  assert_true(parsed.events == [sb(24, [9])])
  match @telnet.TerminalTypeMessage::decode(span([9])) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.TelnetErrorKind::InvalidOptionByte)
      assert_true(e.option == Some(opt(24)))
    }
  }
}

///|
test "TDD START_TLS state model keeps codec separate from transcript security policy" {
  match @telnet.StartTlsMessage::decode(span([0])) {
    Ok(message) => assert_true(message == @telnet.StartTlsMessage::StartTls)
    Err(_) => assert_true(false)
  }
  match @telnet.StartTlsMessage::decode(span([1])) {
    Ok(message) => assert_true(message == @telnet.StartTlsMessage::Follows)
    Err(_) => assert_true(false)
  }
  match @telnet.StartTlsMessage::decode(span([1, 65])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::PolicyRejected)
  }
}

///|
test "TDD unsupported AUTHENTICATION and ENCRYPTION payloads remain raw" {
  match @telnet.OptionPayload::decode(opt(37), span([1, 2, 3])) {
    Ok(payload) =>
      assert_true(
        payload == @telnet.OptionPayload::Raw(opt(37), span([1, 2, 3])),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.OptionPayload::decode(opt(38), span([4, 5])) {
    Ok(payload) =>
      assert_true(payload == @telnet.OptionPayload::Raw(opt(38), span([4, 5])))
    Err(_) => assert_true(false)
  }
}

///|
test "TDD NEW-ENVIRON distinguishes missing empty and escaped values" {
  match
    @telnet.EnvironmentMessage::decode(
      span([0, 0, 65, 1, 2, 66, 67, 0, 68, 1, 1, 2, 0, 69, 2, 1]),
    ) {
    Ok(message) =>
      assert_true(
        message ==
        @telnet.EnvironmentMessage::Is([
          @telnet.EnvironmentVariable::{
            kind: @telnet.EnvironmentVariableKind::Var,
            name: "A",
            value: Some("BC"),
          },
          @telnet.EnvironmentVariable::{
            kind: @telnet.EnvironmentVariableKind::Var,
            name: "D",
            value: Some(""),
          },
          @telnet.EnvironmentVariable::{
            kind: @telnet.EnvironmentVariableKind::Var,
            name: "E",
            value: None,
          },
        ]),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD CHARSET request rejects duplicate separators and empty tokens" {
  match @telnet.CharsetMessage::decode(span([1, 59, 85, 84, 70, 45, 56, 59])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::PolicyRejected)
  }
  match @telnet.CharsetMessage::decode(span([1, 59, 59, 85, 84, 70, 45, 56])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::PolicyRejected)
  }
}

///|
test "TDD LINEMODE SLC remains raw while MODE and forward mask decode semantically" {
  match @telnet.LinemodeMessage::decode(span([3, 1, 2, 3, 4, 5, 6])) {
    Ok(message) =>
      assert_true(
        message == @telnet.LinemodeMessage::Slc(span([1, 2, 3, 4, 5, 6])),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.LinemodeMessage::decode(span([1, 31])) {
    Ok(message) =>
      assert_true(
        message ==
        @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
          flags: [
            @telnet.LinemodeModeFlag::Edit,
            @telnet.LinemodeModeFlag::TrapSig,
            @telnet.LinemodeModeFlag::ModeAck,
            @telnet.LinemodeModeFlag::SoftTab,
            @telnet.LinemodeModeFlag::LitEcho,
          ],
        }),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD NAWS codec accepts protocol range while policy may reject zero later" {
  match @telnet.NawsSize::decode(span([0, 0, 0, 0])) {
    Ok(size) =>
      assert_true(
        size ==
        @telnet.NawsSize::{ columns: (0).to_uint16(), rows: (0).to_uint16() },
      )
    Err(_) => assert_true(false)
  }
  match @telnet.NawsSize::decode(span([255, 255, 255, 255])) {
    Ok(size) =>
      assert_true(
        size ==
        @telnet.NawsSize::{
          columns: (65535).to_uint16(),
          rows: (65535).to_uint16(),
        },
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD TERMINAL-TYPE repeated SEND can encode cycling responses" {
  let encoder = @telnet.Encoder::canonical()
  let first = Bytes::new(11)
  match
    @telnet.TerminalTypeMessage::encode(
      @telnet.TerminalTypeMessage::Is("xterm"),
      first,
    ) {
    Ok(r) => assert_true(r.bytes_written == 6)
    Err(_) => assert_true(false)
  }
  let second = Bytes::new(18)
  match
    @telnet.TerminalTypeMessage::encode(
      @telnet.TerminalTypeMessage::Is("ansi"),
      second,
    ) {
    Ok(r) => assert_true(r.bytes_written == 5)
    Err(_) => assert_true(false)
  }
  assert_true(
    encoder.required_capacity(
      @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: opt(24),
        payload: span([0, 120, 116, 101, 114, 109]),
      }),
    ) ==
    11,
  )
}

///|
test "TDD negotiation storm does not loop and preserves final disabled state" {
  let mut n = @telnet.Negotiator::new()
  let inputs = [
    neg_event(@telnet.NegotiationVerb::Will, 1),
    neg_event(@telnet.NegotiationVerb::Will, 1),
    neg_event(@telnet.NegotiationVerb::Wont, 1),
    neg_event(@telnet.NegotiationVerb::Will, 1),
    neg_event(@telnet.NegotiationVerb::Wont, 1),
  ]
  inputs.each(fn(input) raise {
    let t = n.receive(input, @telnet.PolicyDecision::Accept)
    assert_true(t.actions.length() <= 2)
    n = n.apply(t)
  })
  assert_true(n.state_for(opt(1)).remote_state == @telnet.HalfState::No)
}

///|
test "TDD multiple negotiation actions require atomic output queue planning" {
  let encoder = @telnet.Encoder::canonical()
  let actions = [
    neg_event(@telnet.NegotiationVerb::Do, 1),
    neg_event(@telnet.NegotiationVerb::Will, 3),
  ]
  let too_small = Bytes::make(5, byte(90))
  let first = encoder.encode_negotiation(actions[0], too_small)
  match first {
    Ok(r) => assert_true(r.bytes_written == 3)
    Err(_) => assert_true(false)
  }
  match
    encoder.encode_negotiation(
      actions[1],
      @telnet.ByteSpan::{ bytes: too_small, start: 3, length: 2 }.to_bytes(),
    ) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.required_capacity == 3)
  }
}

///|
test "TDD parser data spans preserve source bytes for future zero-copy ownership" {
  let input = bytes([65, 66, 67])
  let parsed = @telnet.Parser::new(policy_config()).feed(input)
  assert_true(
    parsed.events ==
    [
      @telnet.Event::Data(@telnet.DataEvent::{
        span: @telnet.ByteSpan::{ bytes: input, start: 0, length: 3 },
      }),
    ],
  )
}

///|
test "TDD option string codecs reject invalid UTF-8 byte sequences" {
  match @telnet.TerminalTypeMessage::decode(span([0, 255])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::InvalidOptionByte)
  }
  match @telnet.EnvironmentMessage::decode(span([0, 0, 255])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::InvalidOptionByte)
  }
}

///|
test "TDD IANA mapping samples document unsupported scope as known or unknown" {
  let known = [0, 1, 3, 24, 31, 34, 36, 37, 38, 39, 42, 46, 47, 255]
  known.each(fn(n) raise {
    assert_true(@telnet.KnownOption::from_code(opt(n)).to_code() == opt(n))
  })
  let unsupported_private = [50, 70, 93, 200]
  unsupported_private.each(fn(n) raise {
    assert_true(
      @telnet.KnownOption::from_code(opt(n)) ==
      @telnet.KnownOption::Unknown(opt(n)),
    )
  })
}

///|
test "TDD local request transition input is synthetic outgoing negotiation event" {
  let n = @telnet.Negotiator::new()
  let t = n.request(opt(31), @telnet.OptionSide::Remote, true)
  assert_true(t.input == neg_event(@telnet.NegotiationVerb::Do, 31))
  assert_true(
    t.before == option_state(31, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(
    t.after ==
    option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
  )
}
