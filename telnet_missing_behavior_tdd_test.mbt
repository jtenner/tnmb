// Additional behavioral test families for the public TELNET API.
// These cover parser accounting, encoder equivalence, negotiator metadata,
// option codec roundtrips, and documented policy boundaries.

///|
fn missing_config(
  cr_policy : @telnet.CrPolicy,
  coalescing : @telnet.DataCoalescing,
  strict : Bool,
  data_cap : Int,
  sb_cap : Int,
) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: data_cap,
    max_subnegotiation_bytes: sb_cap,
    cr_policy,
    data_coalescing: coalescing,
    strict_commands: strict,
  }
}

///|
fn missing_default_config() -> @telnet.ParserConfig {
  missing_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    true,
    4096,
    8192,
  )
}

///|
fn missing_output(capacity : Int, sentinel : Int) -> Bytes {
  Bytes::make(capacity, byte(sentinel))
}

///|
fn missing_assert_encoded_prefix(
  output : Bytes,
  expected : Array[Int],
  sentinel : Int,
) -> Unit raise {
  for i = 0; i < expected.length(); i = i + 1 {
    assert_true(output[i] == byte(expected[i]))
  }
  for i = expected.length(); i < output.length(); i = i + 1 {
    assert_true(output[i] == byte(sentinel))
  }
}

///|
fn missing_expect_encoder_method_equivalence(
  item : @telnet.EncodeItem,
  expected : Array[Int],
) -> Unit raise {
  let encoder = @telnet.Encoder::canonical()
  let via_item = missing_output(expected.length() + 3, 222)
  let r1 = encoder.encode_item(item, via_item)
  match r1 {
    Ok(r) => {
      assert_true(r.bytes_written == expected.length())
      missing_assert_encoded_prefix(via_item, expected, 222)
    }
    Err(_) => assert_true(false)
  }
  let direct = missing_output(expected.length() + 3, 221)
  let r2 = match item {
    RawData(span) => encoder.encode_data(span, direct)
    EscapedData(span) => encoder.encode_data(span, direct)
    Command(command) => encoder.encode_command(command, direct)
    Negotiation(event) => encoder.encode_negotiation(event, direct)
    Subnegotiation(event) => encoder.encode_subnegotiation(event, direct)
  }
  match r2 {
    Ok(r) => {
      assert_true(r.bytes_written == expected.length())
      missing_assert_encoded_prefix(direct, expected, 221)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD parser checkpoint modes after partial feeds" {
  let parser = @telnet.Parser::new(missing_default_config())
  let after_iac = parser.feed(bytes([255]))
  assert_true(
    after_iac.parser.checkpoint().mode == @telnet.ParserMode::AfterIac,
  )
  let after_will = parser.feed(bytes([255, 251]))
  assert_true(
    after_will.parser.checkpoint().mode ==
    @telnet.ParserMode::AfterNegotiationVerb(@telnet.NegotiationVerb::Will),
  )
  let after_sb = parser.feed(bytes([255, 250]))
  assert_true(
    after_sb.parser.checkpoint().mode ==
    @telnet.ParserMode::AfterSubnegotiationStart,
  )
  let after_sb_opt = parser.feed(bytes([255, 250, 24, 1]))
  assert_true(
    after_sb_opt.parser.checkpoint().mode ==
    @telnet.ParserMode::InSubnegotiation(opt(24)),
  )
}

///|
test "TDD parser feed_span honors nonzero starts and short lengths" {
  let parser = @telnet.Parser::new(missing_default_config())
  let backing = bytes([99, 65, 255, 255, 66, 100])
  let result = parser.feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 1,
    length: 4,
  })
  assert_true(result.events == [data([65]), data([255]), data([66])])
  assert_true(result.bytes_consumed == 4)
}

///|
test "TDD parser feed_span_into reuses caller event buffer" {
  let parser = @telnet.Parser::new(missing_default_config())
  let events = [cmd(@telnet.Command::NOP)]
  let result = parser.feed_span_into(
    @telnet.ByteSpan::{ bytes: bytes([65, 255, 255]), start: 0, length: 3 },
    events,
  )
  assert_true(result.events == [data([65]), data([255])])
  assert_true(events == result.events)
}

///|
test "TDD parser feed_span preserves partial sequence state" {
  let parser = @telnet.Parser::new(missing_default_config())
  let first = parser.feed_span(@telnet.ByteSpan::{
    bytes: bytes([1, 255, 251, 2]),
    start: 1,
    length: 2,
  })
  assert_true(first.events == [])
  assert_true(
    first.parser.checkpoint().mode ==
    @telnet.ParserMode::AfterNegotiationVerb(@telnet.NegotiationVerb::Will),
  )
  let second = first.parser.feed_span(@telnet.ByteSpan::{
    bytes: bytes([7, 1, 8]),
    start: 1,
    length: 1,
  })
  assert_true(second.events == [neg(@telnet.NegotiationVerb::Will, 1)])
}

///|
test "TDD parser finish is idempotent and complete input has no tail events" {
  let parser = @telnet.Parser::new(missing_default_config())
  let fed = parser.feed(bytes([65, 255, 241]))
  assert_true(fed.events == [data([65]), cmd(@telnet.Command::NOP)])
  let first_finish = fed.parser.finish()
  assert_true(first_finish.events == [])
  assert_true(first_finish.complete)
  let second_finish = first_finish.parser.finish()
  assert_true(second_finish.events == [])
  assert_true(second_finish.complete)
}

///|
test "TDD parser finish does not duplicate dangling IAC errors" {
  let parser = @telnet.Parser::new(missing_default_config())
  let fed = parser.feed(bytes([255]))
  let first_finish = fed.parser.finish()
  assert_true(
    first_finish.events ==
    [err(@telnet.TelnetErrorKind::IncompleteIac, 0, Some(255))],
  )
  let second_finish = first_finish.parser.finish()
  assert_true(second_finish.events == [])
}

///|
test "TDD parser absolute offsets are maintained across chunks" {
  let parser = @telnet.Parser::new(missing_default_config())
  let first = parser.feed(bytes([65, 66]))
  assert_true(first.bytes_consumed == 2)
  let second = first.parser.feed(bytes([255, 42, 67]))
  assert_true(
    second.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 3, Some(42)), data([67])],
  )
  assert_true(second.parser.checkpoint().absolute_offset == 5)
}

///|
test "TDD parser bytes_consumed is precise for partial and error input" {
  let parser = @telnet.Parser::new(missing_default_config())
  let partial = parser.feed(bytes([65, 255]))
  assert_true(partial.bytes_consumed == 2)
  assert_true(partial.events == [data([65])])
  let recovered = partial.parser.feed(bytes([42, 66]))
  assert_true(recovered.bytes_consumed == 2)
  assert_true(
    recovered.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 2, Some(42)), data([66])],
  )
}

///|
test "TDD parser data capacity boundaries include zero one exact and overflow" {
  let zero = @telnet.Parser::new(
    missing_config(
      @telnet.CrPolicy::Preserve,
      @telnet.DataCoalescing::CoalesceUntilCapacity,
      true,
      0,
      8192,
    ),
  ).feed(bytes([65]))
  assert_true(
    zero.events == [err(@telnet.TelnetErrorKind::PolicyRejected, 0, Some(65))],
  )
  let one = @telnet.Parser::new(
    missing_config(
      @telnet.CrPolicy::Preserve,
      @telnet.DataCoalescing::CoalesceUntilCapacity,
      true,
      1,
      8192,
    ),
  ).feed(bytes([65, 66]))
  assert_true(one.events == [data([65]), data([66])])
  let exact = @telnet.Parser::new(
    missing_config(
      @telnet.CrPolicy::Preserve,
      @telnet.DataCoalescing::CoalesceUntilCapacity,
      true,
      3,
      8192,
    ),
  ).feed(bytes([65, 66, 67]))
  assert_true(exact.events == [data([65, 66, 67])])
}

///|
test "TDD parser subnegotiation capacity counts decoded payload bytes" {
  let config = missing_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    true,
    4096,
    1,
  )
  let exact = @telnet.Parser::new(config).feed(
    bytes([255, 250, 31, 255, 255, 255, 240]),
  )
  assert_true(exact.events == [sb(31, [255])])
  let over = @telnet.Parser::new(config).feed(
    bytes([255, 250, 31, 65, 66, 255, 240]),
  )
  assert_true(
    over.events ==
    [err(@telnet.TelnetErrorKind::SubnegotiationTooLarge, 4, Some(66))],
  )
}

///|
test "TDD parser DM and Synch command sequences are byte-level events" {
  let parser = @telnet.Parser::new(missing_default_config())
  let result = parser.feed(bytes([65, 255, 242, 255, 242, 66]))
  assert_true(
    result.events ==
    [data([65]), cmd(@telnet.Command::DM), cmd(@telnet.Command::DM), data([66])],
  )
}

///|
test "TDD encoder accepts and rejects the exhaustive simple command set" {
  let encoder = @telnet.Encoder::canonical()
  let allowed = [
    @telnet.Command::NOP,
    @telnet.Command::DM,
    @telnet.Command::BRK,
    @telnet.Command::IP,
    @telnet.Command::AO,
    @telnet.Command::AYT,
    @telnet.Command::EC,
    @telnet.Command::EL,
    @telnet.Command::GA,
  ]
  allowed.each(fn(command) raise {
    let out = missing_output(4, 17)
    match encoder.encode_command(command, out) {
      Ok(r) => {
        assert_true(r.bytes_written == 2)
        assert_true(out[0] == byte(255))
        assert_true(out[1] == command.to_byte())
        assert_true(out[2] == byte(17))
      }
      Err(_) => assert_true(false)
    }
  })
  let rejected = [
    @telnet.Command::SE,
    @telnet.Command::SB,
    @telnet.Command::WILL,
    @telnet.Command::WONT,
    @telnet.Command::DO,
    @telnet.Command::DONT,
    @telnet.Command::IAC,
  ]
  rejected.each(fn(command) raise {
    let out = missing_output(4, 18)
    match encoder.encode_command(command, out) {
      Ok(_) => assert_true(false)
      Err(e) => {
        assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
        assert_true(out[0] == byte(18))
        assert_true(out[1] == byte(18))
        assert_true(out[2] == byte(18))
        assert_true(out[3] == byte(18))
      }
    }
  })
}

///|
test "TDD encoder specialized methods match encode_item wrappers" {
  missing_expect_encoder_method_equivalence(
    @telnet.EncodeItem::EscapedData(span([65, 255, 66])),
    [65, 255, 255, 66],
  )
  missing_expect_encoder_method_equivalence(
    @telnet.EncodeItem::Command(@telnet.Command::NOP),
    [255, 241],
  )
  missing_expect_encoder_method_equivalence(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 31)),
    [255, 253, 31],
  )
  missing_expect_encoder_method_equivalence(
    @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([0, 80, 0, 24]),
    }),
    [255, 250, 31, 0, 80, 0, 24, 255, 240],
  )
}

///|
test "TDD encoder assume-capacity methods match regular encoders" {
  let encoder = @telnet.Encoder::canonical()
  let data = span([65, 255, 66])
  let data_required = encoder.required_capacity(
    @telnet.EncodeItem::EscapedData(data),
  )
  let data_out = missing_output(data_required, 0)
  match encoder.encode_data_assume_capacity(data, data_out, data_required) {
    Ok(r) => {
      assert_true(r.bytes_written == data_required)
      assert_true(data_out == bytes([65, 255, 255, 66]))
    }
    Err(_) => assert_true(false)
  }
  let event = @telnet.SubnegotiationEvent::{ option: opt(24), payload: data }
  let sb_required = encoder.required_capacity(
    @telnet.EncodeItem::Subnegotiation(event),
  )
  let sb_out = missing_output(sb_required, 0)
  match
    encoder.encode_subnegotiation_assume_capacity(event, sb_out, sb_required) {
    Ok(r) => {
      assert_true(r.bytes_written == sb_required)
      assert_true(sb_out == bytes([255, 250, 24, 65, 255, 255, 66, 255, 240]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD encoder zero-length data and subnegotiation cases" {
  let encoder = @telnet.Encoder::canonical()
  let data_out = missing_output(3, 44)
  match
    encoder.encode_item(@telnet.EncodeItem::EscapedData(span([])), data_out) {
    Ok(r) => {
      assert_true(r.bytes_written == 0)
      assert_true(r.required_capacity == 0)
      assert_true(data_out == bytes([44, 44, 44]))
    }
    Err(_) => assert_true(false)
  }
  let sb_out = missing_output(7, 45)
  match
    encoder.encode_item(
      @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: opt(24),
        payload: span([]),
      }),
      sb_out,
    ) {
    Ok(r) => {
      assert_true(r.bytes_written == 5)
      assert_true(r.required_capacity == 5)
      missing_assert_encoded_prefix(sb_out, [255, 250, 24, 255, 240], 45)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD encoder error metadata reports offset and required capacity" {
  let encoder = @telnet.Encoder::canonical()
  let out = missing_output(1, 77)
  match
    encoder.encode_item(
      @telnet.EncodeItem::Negotiation(
        neg_event(@telnet.NegotiationVerb::Will, 1),
      ),
      out,
    ) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      assert_true(e.offset == 0)
      assert_true(e.required_capacity == 3)
      assert_true(out == bytes([77]))
    }
  }
  match
    encoder.encode_item(
      @telnet.EncodeItem::Command(@telnet.Command::IAC),
      missing_output(2, 78),
    ) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
      assert_true(e.offset == 0)
    }
  }
}

///|
test "TDD negotiator receive is non-mutating until apply" {
  let n = @telnet.Negotiator::new()
  let t = n.receive(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    n.state_for(opt(1)) ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  let after = n.apply(t)
  assert_true(after.state_for(opt(1)) == t.after)
}

///|
test "TDD negotiator option states are independent" {
  let n = @telnet.Negotiator::new()
  let echo = n.request(opt(1), @telnet.OptionSide::Remote, true)
  let n1 = n.apply(echo)
  let naws = n1.request(opt(31), @telnet.OptionSide::Remote, true)
  let n2 = n1.apply(naws)
  let disable_echo = n2.request(opt(1), @telnet.OptionSide::Remote, false)
  let n3 = n2.apply(disable_echo)
  assert_true(n3.state_for(opt(31)) == naws.after)
  assert_true(n3.state_for(opt(1)) == disable_echo.after)
}

///|
test "TDD negotiator full half-state table has exact transition metadata" {
  let cases = [
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
  ]
  cases.each(fn(before) raise {
    let n = @telnet.Negotiator::with_states([before])
    let input = neg_event(@telnet.NegotiationVerb::Wont, 7)
    let t = n.receive(input, @telnet.PolicyDecision::Accept)
    assert_true(t.before == before)
    assert_true(t.input == input)
    assert_true(t.decision == @telnet.PolicyDecision::Accept)
    assert_true(t.after.option == before.option)
  })
}

///|
test "TDD negotiator unknown options reject by default but explicit accept works" {
  let n = @telnet.Negotiator::new()
  let rejected = n.receive(
    neg_event(@telnet.NegotiationVerb::Will, 200),
    @telnet.PolicyDecision::Reject,
  )
  assert_true(
    rejected.after ==
    option_state(200, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(
    rejected.actions ==
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 200),
      ),
    ],
  )
  let accepted = n.receive(
    neg_event(@telnet.NegotiationVerb::Will, 200),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    accepted.after ==
    option_state(200, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )
}

///|
test "TDD option payload roundtrips TerminalType NAWS and START_TLS" {
  let cases = [
    @telnet.OptionPayload::TerminalType(@telnet.TerminalTypeMessage::Send),
    @telnet.OptionPayload::TerminalType(
      @telnet.TerminalTypeMessage::Is("xterm-256color"),
    ),
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (132).to_uint16(),
      rows: (43).to_uint16(),
    }),
    @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::StartTls),
    @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows),
  ]
  cases.each(fn(payload) raise {
    let capacity = @telnet.OptionPayload::required_capacity(payload)
    let output = Bytes::new(capacity)
    match @telnet.OptionPayload::encode(payload, output) {
      Ok(r) => {
        assert_true(r.bytes_written == capacity)
        let option = match payload {
          TerminalType(_) => opt(24)
          Naws(_) => opt(31)
          StartTls(_) => opt(46)
          _ => opt(0)
        }
        match
          @telnet.OptionPayload::decode(option, @telnet.ByteSpan::{
            bytes: output,
            start: 0,
            length: r.bytes_written,
          }) {
          Ok(decoded) => assert_true(decoded == payload)
          Err(_) => assert_true(false)
        }
      }
      Err(_) => assert_true(false)
    }
  })
}

///|
test "TDD option payload roundtrips Environment Charset and Linemode" {
  let cases = [
    @telnet.OptionPayload::Environment(
      @telnet.EnvironmentMessage::Is([
        @telnet.EnvironmentVariable::{
          kind: @telnet.EnvironmentVariableKind::Var,
          name: "USER",
          value: Some("moon"),
        },
        @telnet.EnvironmentVariable::{
          kind: @telnet.EnvironmentVariableKind::UserVar,
          name: "EMPTY",
          value: Some(""),
        },
      ]),
    ),
    @telnet.OptionPayload::Environment(
      @telnet.EnvironmentMessage::Send(["TERM", "USER"]),
    ),
    @telnet.OptionPayload::Charset(
      @telnet.CharsetMessage::Request(["UTF-8", "US-ASCII"]),
    ),
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::Rejected),
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
        flags: [
          @telnet.LinemodeModeFlag::Edit,
          @telnet.LinemodeModeFlag::LitEcho,
        ],
      }),
    ),
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::ForwardMask(
        @telnet.LinemodeForwardMask::Bytes(span([0, 1, 255])),
      ),
    ),
  ]
  cases.each(fn(payload) raise {
    let capacity = @telnet.OptionPayload::required_capacity(payload)
    let output = Bytes::new(capacity)
    match @telnet.OptionPayload::encode(payload, output) {
      Ok(r) => {
        let option = match payload {
          Environment(_) => opt(39)
          Charset(_) => opt(42)
          Linemode(_) => opt(34)
          _ => opt(0)
        }
        match
          @telnet.OptionPayload::decode(option, @telnet.ByteSpan::{
            bytes: output,
            start: 0,
            length: r.bytes_written,
          }) {
          Ok(decoded) => assert_true(decoded == payload)
          Err(_) => assert_true(false)
        }
      }
      Err(_) => assert_true(false)
    }
  })
}

///|
test "TDD option codec string and byte edge cases are explicit" {
  let ttype = @telnet.TerminalTypeMessage::Is("xterm\u0000raw")
  let out = Bytes::new(32)
  match @telnet.TerminalTypeMessage::encode(ttype, out) {
    Ok(r) => {
      assert_true(r.bytes_written > 0)
      match
        @telnet.TerminalTypeMessage::decode(@telnet.ByteSpan::{
          bytes: out,
          start: 0,
          length: r.bytes_written,
        }) {
        Ok(decoded) => assert_true(decoded == ttype)
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TDD parser keeps START_TLS transcript policy out of raw parsing" {
  let parser = @telnet.Parser::new(missing_default_config())
  let first = parser.feed(bytes([255, 250, 46, 1, 255, 240]))
  assert_true(first.events == [sb(46, [1])])
  let repeat = first.parser.feed(bytes([255, 250, 46, 1, 255, 240]))
  assert_true(repeat.events == [sb(46, [1])])
  let cleartext = repeat.parser.feed(bytes([65]))
  assert_true(cleartext.events == [data([65])])
}

///|
test "TDD binary-mode CR fixture records directional future session behavior" {
  let n = @telnet.Negotiator::with_states([
    option_state(0, @telnet.HalfState::No, @telnet.HalfState::Yes),
  ])
  assert_true(n.state_for(opt(0)).remote_state == @telnet.HalfState::Yes)
  let parser = @telnet.Parser::new(
    missing_config(
      @telnet.CrPolicy::Preserve,
      @telnet.DataCoalescing::CoalesceUntilCommand,
      true,
      4096,
      8192,
    ),
  )
  assert_true(parser.feed(bytes([13])).events == [data([13])])
}
