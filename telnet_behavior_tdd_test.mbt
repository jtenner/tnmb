// Behavioral tests for the public TELNET API. These exercise the production
// parser, encoder, negotiator, mapping helpers, and option codecs directly.

///|
fn assert_parser_events(
  wire : Array[Int],
  expected : Array[@telnet.Event],
) -> Unit raise {
  let parser = @telnet.Parser::default()
  let result = parser.feed(bytes(wire))
  assert_true(result.events == expected)
  assert_true(result.bytes_consumed == wire.length())
}

///|
fn assert_parser_finish(
  wire : Array[Int],
  expected : Array[@telnet.Event],
) -> Unit raise {
  let parser = @telnet.Parser::default()
  let fed = parser.feed(bytes(wire))
  let finished = fed.parser.finish()
  assert_true(finished.events == expected)
}

///|
fn assert_encoded(
  item : @telnet.EncodeItem,
  expected : Array[Int],
) -> Unit raise {
  let encoder = @telnet.Encoder::canonical()
  let output = Bytes::new(expected.length())
  let result = encoder.encode_item(item, output)
  match result {
    Ok(r) => {
      assert_true(r.bytes_written == expected.length())
      assert_true(output == bytes(expected))
    }
    Err(_) => assert_true(false)
  }
}

///|
fn assert_encode_error(
  item : @telnet.EncodeItem,
  capacity : Int,
  kind : @telnet.EncodeErrorKind,
) -> Unit raise {
  let encoder = @telnet.Encoder::canonical()
  let output = Bytes::new(capacity)
  let result = encoder.encode_item(item, output)
  match result {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == kind)
  }
}

///|
fn assert_transition(
  input : @telnet.NegotiationEvent,
  decision : @telnet.PolicyDecision,
  expected_after : @telnet.OptionState,
  expected_actions : Array[@telnet.NegotiationAction],
) -> Unit raise {
  let negotiator = @telnet.Negotiator::new()
  let transition = negotiator.receive(input, decision)
  assert_true(transition.after == expected_after)
  assert_true(transition.actions == expected_actions)
}

///|
test "TDD parser parses ordinary data" {
  assert_parser_events([65, 66, 67], [data([65, 66, 67])])
}

///|
test "TDD parser preserves NUL data" {
  assert_parser_events([65, 0, 66], [data([65, 0, 66])])
}

///|
test "TDD parser unescapes IAC IAC as data" {
  assert_parser_events([255, 255], [data([255])])
}

///|
test "TDD parser orders data escaped IAC and trailing data" {
  assert_parser_events([65, 255, 255, 66], [data([65]), data([255]), data([66])])
}

///|
test "TDD parser parses NOP command" {
  assert_parser_events([255, 241], [cmd(@telnet.Command::NOP)])
}

///|
test "TDD parser parses AYT command between data" {
  assert_parser_events([65, 255, 246, 66], [
    data([65]),
    cmd(@telnet.Command::AYT),
    data([66]),
  ])
}

///|
test "TDD parser parses all simple commands" {
  assert_parser_events(
    [255, 242, 255, 243, 255, 244, 255, 245, 255, 247, 255, 248, 255, 249],
    [
      cmd(@telnet.Command::DM),
      cmd(@telnet.Command::BRK),
      cmd(@telnet.Command::IP),
      cmd(@telnet.Command::AO),
      cmd(@telnet.Command::EC),
      cmd(@telnet.Command::EL),
      cmd(@telnet.Command::GA),
    ],
  )
}

///|
test "TDD parser parses WILL ECHO" {
  assert_parser_events([255, 251, 1], [neg(@telnet.NegotiationVerb::Will, 1)])
}

///|
test "TDD parser parses WONT ECHO" {
  assert_parser_events([255, 252, 1], [neg(@telnet.NegotiationVerb::Wont, 1)])
}

///|
test "TDD parser parses DO NAWS" {
  assert_parser_events([255, 253, 31], [neg(@telnet.NegotiationVerb::Do, 31)])
}

///|
test "TDD parser parses DONT NAWS" {
  assert_parser_events([255, 254, 31], [neg(@telnet.NegotiationVerb::Dont, 31)])
}

///|
test "TDD parser parses TTYPE SEND subnegotiation" {
  assert_parser_events([255, 250, 24, 1, 255, 240], [sb(24, [1])])
}

///|
test "TDD parser parses TTYPE IS subnegotiation" {
  assert_parser_events([255, 250, 24, 0, 120, 116, 101, 114, 109, 255, 240], [
    sb(24, [0, 120, 116, 101, 114, 109]),
  ])
}

///|
test "TDD parser parses NAWS subnegotiation" {
  assert_parser_events([255, 250, 31, 0, 80, 0, 24, 255, 240], [
    sb(31, [0, 80, 0, 24]),
  ])
}

///|
test "TDD parser unescapes IAC inside subnegotiation" {
  assert_parser_events([255, 250, 31, 0, 255, 255, 0, 24, 255, 240], [
    sb(31, [0, 255, 0, 24]),
  ])
}

///|
test "TDD parser reports dangling IAC on finish" {
  assert_parser_finish([255], [
    err(@telnet.TelnetErrorKind::IncompleteIac, 0, Some(255)),
  ])
}

///|
test "TDD parser reports dangling negotiation on finish" {
  assert_parser_finish([255, 251], [
    err(@telnet.TelnetErrorKind::IncompleteNegotiation, 1, Some(251)),
  ])
}

///|
test "TDD parser reports dangling subnegotiation on finish" {
  assert_parser_finish([255, 250, 24, 1], [
    err(@telnet.TelnetErrorKind::IncompleteSubnegotiation, 3, Some(1)),
  ])
}

///|
test "TDD parser rejects invalid strict IAC command" {
  let parser = @telnet.Parser::new(preserve_config())
  let result = parser.feed(bytes([255, 42]))
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(42))],
  )
}

///|
test "TDD parser supports checkpoint and restore" {
  let parser = @telnet.Parser::default()
  let first = parser.feed(bytes([255]))
  let checkpoint = first.parser.checkpoint()
  let restored = @telnet.Parser::restore(first.parser.config, checkpoint)
  let second = restored.feed(bytes([241]))
  assert_true(second.events == [cmd(@telnet.Command::NOP)])
}

///|
test "TDD parser reset returns normal empty parser" {
  let parser = @telnet.Parser::default()
  let after = parser.feed(bytes([255])).parser.reset()
  assert_true(after.checkpoint.mode == @telnet.ParserMode::Normal)
}

///|
test "TDD encoder encodes plain data" {
  assert_encoded(@telnet.EncodeItem::EscapedData(span([65, 66, 67])), [
    65, 66, 67,
  ])
}

///|
test "TDD encoder doubles IAC in data" {
  assert_encoded(@telnet.EncodeItem::EscapedData(span([65, 255, 66])), [
    65, 255, 255, 66,
  ])
}

///|
test "TDD encoder encodes NOP command" {
  assert_encoded(@telnet.EncodeItem::Command(@telnet.Command::NOP), [255, 241])
}

///|
test "TDD encoder rejects direct IAC command in canonical mode" {
  assert_encode_error(
    @telnet.EncodeItem::Command(@telnet.Command::IAC),
    2,
    @telnet.EncodeErrorKind::UnsupportedEncoding,
  )
}

///|
test "TDD encoder encodes WILL ECHO" {
  assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Will, 1)),
    [255, 251, 1],
  )
}

///|
test "TDD encoder encodes DONT NAWS" {
  assert_encoded(
    @telnet.EncodeItem::Negotiation(
      neg_event(@telnet.NegotiationVerb::Dont, 31),
    ),
    [255, 254, 31],
  )
}

///|
test "TDD encoder encodes TTYPE SEND subnegotiation" {
  assert_encoded(
    @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(24),
      payload: span([1]),
    }),
    [255, 250, 24, 1, 255, 240],
  )
}

///|
test "TDD encoder escapes IAC in subnegotiation payload" {
  assert_encoded(
    @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([0, 255, 0, 24]),
    }),
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
  )
}

///|
test "TDD encoder reports output buffer too small" {
  assert_encode_error(
    @telnet.EncodeItem::EscapedData(span([255])),
    1,
    @telnet.EncodeErrorKind::OutputBufferTooSmall,
  )
}

///|
test "TDD encoder computes escaped data required capacity" {
  let encoder = @telnet.Encoder::canonical()
  assert_true(
    encoder.required_capacity(
      @telnet.EncodeItem::EscapedData(span([65, 255, 66])),
    ) ==
    4,
  )
}

///|
test "TDD encoder computes subnegotiation required capacity" {
  let encoder = @telnet.Encoder::canonical()
  assert_true(
    encoder.required_capacity(
      @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: opt(31),
        payload: span([0, 255, 0, 24]),
      }),
    ) ==
    10,
  )
}

///|
test "TDD negotiator accepts WILL ECHO from disabled remote half" {
  assert_transition(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Accept,
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
    [
      @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 1)),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Remote, opt(1)),
    ],
  )
}

///|
test "TDD negotiator rejects WILL unknown by default" {
  assert_transition(
    neg_event(@telnet.NegotiationVerb::Will, 93),
    @telnet.PolicyDecision::Reject,
    option_state(93, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 93),
      ),
    ],
  )
}

///|
test "TDD negotiator accepts DO ECHO from disabled local half" {
  assert_transition(
    neg_event(@telnet.NegotiationVerb::Do, 1),
    @telnet.PolicyDecision::Accept,
    option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 1),
      ),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Local, opt(1)),
    ],
  )
}

///|
test "TDD negotiator disables local option on DONT" {
  let negotiator = @telnet.Negotiator::with_states([
    option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
  ])
  let transition = negotiator.receive(
    neg_event(@telnet.NegotiationVerb::Dont, 1),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    transition.after ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(
    transition.actions ==
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 1),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(1)),
    ],
  )
}

///|
test "TDD negotiator ignores duplicate WILL on enabled remote half" {
  let negotiator = @telnet.Negotiator::with_states([
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
  ])
  let transition = negotiator.receive(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Ignore,
  )
  assert_true(
    transition.after ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )
  assert_true(transition.actions == [@telnet.NegotiationAction::NoAction])
}

///|
test "TDD negotiator initiates remote option enable with DO" {
  let negotiator = @telnet.Negotiator::new()
  let transition = negotiator.request(opt(31), @telnet.OptionSide::Remote, true)
  assert_true(
    transition.after ==
    option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
  )
  assert_true(
    transition.actions ==
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Do, 31),
      ),
    ],
  )
}

///|
test "TDD negotiator initiates local option enable with WILL" {
  let negotiator = @telnet.Negotiator::new()
  let transition = negotiator.request(opt(31), @telnet.OptionSide::Local, true)
  assert_true(
    transition.after ==
    option_state(
      31,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
  )
  assert_true(
    transition.actions ==
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 31),
      ),
    ],
  )
}

///|
test "TDD command byte mapping" {
  assert_true(
    @telnet.Command::from_byte(byte(255)) == Some(@telnet.Command::IAC),
  )
  assert_true(
    @telnet.Command::from_byte(byte(241)) == Some(@telnet.Command::NOP),
  )
  assert_true(@telnet.Command::from_byte(byte(42)) == None)
  assert_true(@telnet.Command::GA.to_byte() == byte(249))
}

///|
test "TDD negotiation verb command mapping" {
  assert_true(
    @telnet.NegotiationVerb::from_command(@telnet.Command::WILL) ==
    Some(@telnet.NegotiationVerb::Will),
  )
  assert_true(
    @telnet.NegotiationVerb::from_command(@telnet.Command::NOP) == None,
  )
  assert_true(@telnet.NegotiationVerb::Do.to_command() == @telnet.Command::DO)
}

///|
test "TDD option code and known option mapping" {
  assert_true(@telnet.OptionCode::new(byte(31)) == opt(31))
  assert_true(opt(31).to_byte() == byte(31))
  assert_true(
    @telnet.KnownOption::from_code(opt(31)) == @telnet.KnownOption::Naws,
  )
  assert_true(@telnet.KnownOption::Naws.to_code() == opt(31))
  assert_true(
    @telnet.KnownOption::from_code(opt(93)) ==
    @telnet.KnownOption::Unknown(opt(93)),
  )
}

///|
test "TDD ByteSpan helpers validate and copy selected bytes" {
  let s = @telnet.ByteSpan::new(bytes([65, 66, 67, 68]), 1, 2)
  assert_true(s.is_empty() == false)
  assert_true(s.to_bytes() == bytes([66, 67]))
}

///|
test "TDD OptionPayload decodes TERMINAL-TYPE SEND" {
  let decoded = @telnet.OptionPayload::decode(opt(24), span([1]))
  match decoded {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::TerminalType(@telnet.TerminalTypeMessage::Send),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD OptionPayload decodes TERMINAL-TYPE IS" {
  let decoded = @telnet.OptionPayload::decode(
    opt(24),
    span([0, 120, 116, 101, 114, 109]),
  )
  match decoded {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::TerminalType(
          @telnet.TerminalTypeMessage::Is("xterm"),
        ),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD OptionPayload decodes NAWS" {
  let decoded = @telnet.OptionPayload::decode(opt(31), span([0, 80, 0, 24]))
  match decoded {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Naws(@telnet.NawsSize::{
          columns: (80).to_uint16(),
          rows: (24).to_uint16(),
        }),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD OptionPayload rejects malformed NAWS length" {
  let decoded = @telnet.OptionPayload::decode(opt(31), span([0, 80, 0]))
  match decoded {
    Ok(_) => assert_true(false)
    Err(e) =>
      assert_true(e.kind == @telnet.TelnetErrorKind::IncompleteSubnegotiation)
  }
}

///|
test "TDD OptionPayload decodes NEW-ENVIRON SEND" {
  let decoded = @telnet.OptionPayload::decode(
    opt(39),
    span([1, 0, 84, 69, 82, 77]),
  )
  match decoded {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Environment(
          @telnet.EnvironmentMessage::Send(["TERM"]),
        ),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD OptionPayload decodes CHARSET ACCEPTED" {
  let decoded = @telnet.OptionPayload::decode(
    opt(42),
    span([2, 85, 84, 70, 45, 56]),
  )
  match decoded {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Charset(
          @telnet.CharsetMessage::Accepted("UTF-8"),
        ),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD OptionPayload decodes LINEMODE MODE" {
  let decoded = @telnet.OptionPayload::decode(opt(34), span([1, 3]))
  match decoded {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Linemode(
          @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
            flags: [
              @telnet.LinemodeModeFlag::Edit,
              @telnet.LinemodeModeFlag::TrapSig,
            ],
          }),
        ),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD OptionPayload decodes START_TLS FOLLOWS" {
  let decoded = @telnet.OptionPayload::decode(opt(46), span([1]))
  match decoded {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD specific NAWS codec decodes 80x24" {
  let decoded = @telnet.NawsSize::decode(span([0, 80, 0, 24]))
  match decoded {
    Ok(size) =>
      assert_true(
        size ==
        @telnet.NawsSize::{ columns: (80).to_uint16(), rows: (24).to_uint16() },
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD specific START_TLS codec encodes follows" {
  let output = Bytes::new(1)
  let encoded = @telnet.StartTlsMessage::encode(
    @telnet.StartTlsMessage::Follows,
    output,
  )
  match encoded {
    Ok(r) => {
      assert_true(r.bytes_written == 1)
      assert_true(output == bytes([1]))
    }
    Err(_) => assert_true(false)
  }
}
