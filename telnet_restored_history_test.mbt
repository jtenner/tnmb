// Restored regression tests distilled from useful scenarios that previously only
// described fixtures. These exercise the public parser, negotiator, encoder,
// and option-codec APIs directly.

///|
fn restored_send_actions(
  actions : Array[@telnet.NegotiationAction],
) -> Array[@telnet.NegotiationEvent] {
  let sends = Array::new()
  actions.each(fn(action) {
    match action {
      @telnet.NegotiationAction::Send(e) => sends.push(e)
      _ => ()
    }
  })
  sends
}

///|
fn restored_assert_sends(
  transition : @telnet.NegotiationTransition,
  expected : Array[@telnet.NegotiationEvent],
) -> Unit raise {
  assert_true(restored_send_actions(transition.actions) == expected)
}

///|
fn restored_assert_parse(
  wire : Array[Int],
  expected : Array[@telnet.Event],
) -> @telnet.Parser raise {
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.bytes_consumed == wire.length())
  assert_true(result.events == expected)
  assert_true(result.parser.checkpoint.mode == @telnet.ParserMode::Normal)
  result.parser
}

///|
fn restored_payload_at(
  events : Array[@telnet.Event],
  index : Int,
) -> @telnet.OptionPayload raise {
  match events[index] {
    @telnet.Event::Subnegotiation(s) =>
      match @telnet.OptionPayload::decode(s.option, s.payload) {
        Ok(payload) => payload
        Err(_) => {
          assert_true(false)
          @telnet.OptionPayload::Empty
        }
      }
    _ => {
      assert_true(false)
      @telnet.OptionPayload::Empty
    }
  }
}

///|
fn restored_expect_decode_error(
  option : Int,
  payload : Array[Int],
  kind : @telnet.TelnetErrorKind,
) -> Unit raise {
  match @telnet.OptionPayload::decode(opt(option), span(payload)) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == kind)
      match e.option {
        Some(actual) => assert_true(actual == opt(option))
        None => ()
      }
    }
  }
}

///|
fn restored_payload_with_iacs(
  length : Int,
  iac_count : Int,
) -> @telnet.ByteSpan {
  let data = Array::make(length, byte(65))
  for i = 0; i < iac_count; i = i + 1 {
    data[i] = byte(255)
  }
  let bs = Bytes::from_array(data)
  @telnet.ByteSpan::{ bytes: bs, start: 0, length: bs.length() }
}

///|
test "restored history login transcript drives parser and negotiator" {
  let parser = @telnet.Parser::default()
  let first = parser.feed(bytes([255, 251, 1, 255, 251, 3]))
  assert_true(
    first.events ==
    [
      neg(@telnet.NegotiationVerb::Will, 1),
      neg(@telnet.NegotiationVerb::Will, 3),
    ],
  )
  let negotiator0 = @telnet.Negotiator::new()
  let echo_on = negotiator0.receive(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Accept,
  )
  restored_assert_sends(echo_on, [neg_event(@telnet.NegotiationVerb::Do, 1)])
  let negotiator1 = negotiator0.apply(echo_on)
  let sga_on = negotiator1.receive(
    neg_event(@telnet.NegotiationVerb::Will, 3),
    @telnet.PolicyDecision::Accept,
  )
  restored_assert_sends(sga_on, [neg_event(@telnet.NegotiationVerb::Do, 3)])
  let negotiator2 = negotiator1.apply(sga_on)
  assert_true(
    negotiator2.state_for(opt(1)) ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )
  assert_true(
    negotiator2.state_for(opt(3)) ==
    option_state(3, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )

  let prompt = first.parser.feed(bytes([108, 111, 103, 105, 110, 58, 32]))
  assert_true(prompt.events == [data([108, 111, 103, 105, 110, 58, 32])])

  let password = prompt.parser.feed(
    bytes([255, 252, 1, 80, 97, 115, 115, 119, 111, 114, 100, 58, 32]),
  )
  assert_true(
    password.events ==
    [
      neg(@telnet.NegotiationVerb::Wont, 1),
      data([80, 97, 115, 115, 119, 111, 114, 100, 58, 32]),
    ],
  )
  let echo_off = negotiator2.receive(
    neg_event(@telnet.NegotiationVerb::Wont, 1),
    @telnet.PolicyDecision::Accept,
  )
  restored_assert_sends(echo_off, [])
  let negotiator3 = negotiator2.apply(echo_off)
  assert_true(
    negotiator3.state_for(opt(1)) ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(
    negotiator3.state_for(opt(3)) ==
    option_state(3, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )
}

///|
test "restored history NAWS and TTYPE startup decodes negotiated payloads" {
  let parser = @telnet.Parser::default()
  let requested = parser.feed(bytes([255, 253, 31, 255, 253, 24]))
  assert_true(
    requested.events ==
    [neg(@telnet.NegotiationVerb::Do, 31), neg(@telnet.NegotiationVerb::Do, 24)],
  )
  let negotiator0 = @telnet.Negotiator::new()
  let naws = negotiator0.receive(
    neg_event(@telnet.NegotiationVerb::Do, 31),
    @telnet.PolicyDecision::Accept,
  )
  restored_assert_sends(naws, [neg_event(@telnet.NegotiationVerb::Will, 31)])
  let negotiator1 = negotiator0.apply(naws)
  let ttype = negotiator1.receive(
    neg_event(@telnet.NegotiationVerb::Do, 24),
    @telnet.PolicyDecision::Accept,
  )
  restored_assert_sends(ttype, [neg_event(@telnet.NegotiationVerb::Will, 24)])
  let negotiator2 = negotiator1.apply(ttype)
  assert_true(
    negotiator2.state_for(opt(31)) ==
    option_state(31, @telnet.HalfState::Yes, @telnet.HalfState::No),
  )
  assert_true(
    negotiator2.state_for(opt(24)) ==
    option_state(24, @telnet.HalfState::Yes, @telnet.HalfState::No),
  )

  let naws_payload = requested.parser.feed(
    bytes([255, 250, 31, 0, 80, 0, 24, 255, 240]),
  )
  assert_true(naws_payload.events == [sb(31, [0, 80, 0, 24])])
  assert_true(
    restored_payload_at(naws_payload.events, 0) ==
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (80).to_uint16(),
      rows: (24).to_uint16(),
    }),
  )

  let ttype_send = naws_payload.parser.feed(bytes([255, 250, 24, 1, 255, 240]))
  assert_true(ttype_send.events == [sb(24, [1])])
  assert_true(
    restored_payload_at(ttype_send.events, 0) ==
    @telnet.OptionPayload::TerminalType(@telnet.TerminalTypeMessage::Send),
  )

  let ttype_is = ttype_send.parser.feed(
    bytes([255, 250, 24, 0, 120, 116, 101, 114, 109, 255, 240]),
  )
  assert_true(ttype_is.events == [sb(24, [0, 120, 116, 101, 114, 109])])
  assert_true(
    restored_payload_at(ttype_is.events, 0) ==
    @telnet.OptionPayload::TerminalType(
      @telnet.TerminalTypeMessage::Is("xterm"),
    ),
  )
}

///|
test "restored history MUD unknown option is rejected while common options remain enabled" {
  let parser = @telnet.Parser::default()
  let banner = parser.feed(
    bytes([77, 85, 68, 32, 114, 101, 97, 100, 121, 13, 10]),
  )
  assert_true(
    banner.events == [data([77, 85, 68, 32, 114, 101, 97, 100, 121, 13, 10])],
  )
  let common = banner.parser.feed(bytes([255, 251, 1, 255, 251, 3]))
  assert_true(
    common.events ==
    [
      neg(@telnet.NegotiationVerb::Will, 1),
      neg(@telnet.NegotiationVerb::Will, 3),
    ],
  )
  let negotiator0 = @telnet.Negotiator::new()
  let echo = negotiator0.receive(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Accept,
  )
  let negotiator1 = negotiator0.apply(echo)
  let sga = negotiator1.receive(
    neg_event(@telnet.NegotiationVerb::Will, 3),
    @telnet.PolicyDecision::Accept,
  )
  let negotiator2 = negotiator1.apply(sga)

  let zmp = common.parser.feed(bytes([255, 251, 93]))
  assert_true(zmp.events == [neg(@telnet.NegotiationVerb::Will, 93)])
  let rejected = negotiator2.receive(
    neg_event(@telnet.NegotiationVerb::Will, 93),
    @telnet.PolicyDecision::Reject,
  )
  restored_assert_sends(rejected, [neg_event(@telnet.NegotiationVerb::Dont, 93)])
  let negotiator3 = negotiator2.apply(rejected)
  assert_true(
    negotiator3.state_for(opt(1)) ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )
  assert_true(
    negotiator3.state_for(opt(3)) ==
    option_state(3, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )
  assert_true(
    negotiator3.state_for(opt(93)) ==
    option_state(93, @telnet.HalfState::No, @telnet.HalfState::No),
  )
}

///|
test "restored history parser recovery cases assert actual events" {
  ignore(
    restored_assert_parse([255, 42, 255, 241], [
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(42)),
      cmd(@telnet.Command::NOP),
    ]),
  )
  ignore(
    restored_assert_parse([255, 240, 65], [
      err(@telnet.TelnetErrorKind::UnexpectedSubnegotiationEnd, 1, Some(240)),
      data([65]),
    ]),
  )
  ignore(
    restored_assert_parse([255, 244, 255, 242], [
      cmd(@telnet.Command::IP),
      cmd(@telnet.Command::DM),
    ]),
  )
  ignore(
    restored_assert_parse([255, 245, 255, 242], [
      cmd(@telnet.Command::AO),
      cmd(@telnet.Command::DM),
    ]),
  )
}

///|
test "restored history NVT CR chunks recover across every split point" {
  let config = tdd_config(
    @telnet.CrPolicy::ValidateNvt,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    true,
    4096,
    8192,
  )
  let crlf = [13, 10]
  for split = 0; split <= crlf.length(); split = split + 1 {
    assert_true(tdd_feed_split(config, crlf, split) == [data([13, 10])])
  }
  let crnul = [13, 0]
  for split = 0; split <= crnul.length(); split = split + 1 {
    assert_true(tdd_feed_split(config, crnul, split) == [data([13, 0])])
  }
  let cr_command = [13, 255, 241]
  for split = 0; split <= cr_command.length(); split = split + 1 {
    assert_true(
      tdd_feed_split(config, cr_command, split) ==
      [
        err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(255)),
        cmd(@telnet.Command::NOP),
      ],
    )
  }
}

///|
test "restored history option codec malformed matrix checks errors" {
  restored_expect_decode_error(
    24,
    [],
    @telnet.TelnetErrorKind::IncompleteSubnegotiation,
  )
  restored_expect_decode_error(
    24,
    [1, 1],
    @telnet.TelnetErrorKind::InvalidOptionByte,
  )
  restored_expect_decode_error(
    24,
    [255],
    @telnet.TelnetErrorKind::InvalidOptionByte,
  )
  restored_expect_decode_error(
    24,
    [0, 255],
    @telnet.TelnetErrorKind::InvalidOptionByte,
  )
  let invalid_naws_lengths = [0, 1, 2, 3, 5, 6, 7, 8]
  invalid_naws_lengths.each(fn(n) raise {
    let payload = Array::make(n, 0)
    restored_expect_decode_error(
      31,
      payload,
      @telnet.TelnetErrorKind::IncompleteSubnegotiation,
    )
  })
  restored_expect_decode_error(42, [1], @telnet.TelnetErrorKind::PolicyRejected)
  restored_expect_decode_error(
    42,
    [1, 32, 32],
    @telnet.TelnetErrorKind::PolicyRejected,
  )
  restored_expect_decode_error(42, [2], @telnet.TelnetErrorKind::PolicyRejected)
  restored_expect_decode_error(42, [4], @telnet.TelnetErrorKind::PolicyRejected)
  match
    @telnet.OptionPayload::decode(
      opt(42),
      span([4, 108, 97, 116, 105, 110, 49]),
    ) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Charset(
          @telnet.CharsetMessage::TTableIs("latin1"),
        ),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.OptionPayload::decode(opt(42), span([5])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableRejected),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.OptionPayload::decode(opt(42), span([6])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableAck),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.OptionPayload::decode(opt(42), span([7])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableNak),
      )
    Err(_) => assert_true(false)
  }
  restored_expect_decode_error(
    42,
    [99],
    @telnet.TelnetErrorKind::InvalidCommandByte,
  )
  restored_expect_decode_error(46, [], @telnet.TelnetErrorKind::PolicyRejected)
  restored_expect_decode_error(
    46,
    [0, 0],
    @telnet.TelnetErrorKind::PolicyRejected,
  )
  restored_expect_decode_error(
    46,
    [1, 65],
    @telnet.TelnetErrorKind::PolicyRejected,
  )
}

///|
test "restored history encoder capacity matrix uses production formulas" {
  let encoder = @telnet.Encoder::canonical()
  let data_lengths = [0, 1, 1, 2, 2, 2, 255, 4096]
  let data_iacs = [0, 0, 1, 0, 1, 2, 1, 128]
  for i = 0; i < data_lengths.length(); i = i + 1 {
    let length = data_lengths[i]
    let iacs = data_iacs[i]
    let payload = restored_payload_with_iacs(length, iacs)
    assert_true(
      encoder.required_capacity(@telnet.EncodeItem::EscapedData(payload)) ==
      length + iacs,
    )
  }
  let subneg_lengths = [0, 1, 1, 4, 255, 4096]
  let subneg_iacs = [0, 0, 1, 0, 10, 128]
  for i = 0; i < subneg_lengths.length(); i = i + 1 {
    let length = subneg_lengths[i]
    let iacs = subneg_iacs[i]
    let payload = restored_payload_with_iacs(length, iacs)
    let item = @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(39),
      payload,
    })
    assert_true(encoder.required_capacity(item) == 5 + length + iacs)
  }
}
