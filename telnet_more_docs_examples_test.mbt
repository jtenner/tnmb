// Additional executable documentation-style examples for common library usage.

///|
test "docs example streaming parser over arbitrary chunks" {
  let mut parser = @telnet.Parser::default()
  let mut events : Array[@telnet.Event] = []
  [[72], [105, 255], [241], [33]].each(fn(chunk) {
    let result = parser.feed(bytes(chunk))
    events = events + result.events
    parser = result.parser
  })
  assert_true(
    events_semantically_equal(events, [
      data([72]),
      data([105]),
      cmd(@telnet.Command::NOP),
      data([33]),
    ]),
  )
}

///|
test "docs example negotiate remote ECHO acceptance" {
  let negotiator = @telnet.Negotiator::new()
  let transition = negotiator.receive(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    transition.after ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )
  assert_true(
    transition.actions[0] ==
    @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 1)),
  )
  let updated = negotiator.apply(transition)
  assert_true(updated.state_for(opt(1)).remote_state == @telnet.HalfState::Yes)
}

///|
test "docs example encode TTYPE IS subnegotiation" {
  let payload = @telnet.OptionPayload::TerminalType(
    @telnet.TerminalTypeMessage::Is("xterm"),
  )
  let payload_bytes = Bytes::new(
    @telnet.OptionPayload::required_capacity(payload),
  )
  match @telnet.OptionPayload::encode(payload, payload_bytes) {
    Ok(r) => {
      let item = @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: opt(24),
        payload: @telnet.ByteSpan::{
          bytes: payload_bytes,
          start: 0,
          length: r.bytes_written,
        },
      })
      let wire = Bytes::new(
        @telnet.Encoder::canonical().required_capacity(item),
      )
      match @telnet.Encoder::canonical().encode_item(item, wire) {
        Ok(_) =>
          assert_true(
            wire == bytes([255, 250, 24, 0, 120, 116, 101, 114, 109, 255, 240]),
          )
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
test "docs example decode environment send request" {
  let payload = span([1, 0, 84, 69, 82, 77, 0, 85, 83, 69, 82])
  match @telnet.OptionPayload::decode(opt(39), payload) {
    Ok(
      @telnet.OptionPayload::Environment(
        @telnet.EnvironmentMessage::Send(names)
      )
    ) => assert_true(names == ["TERM", "USER"])
    _ => assert_true(false)
  }
}

///|
test "docs example reject unknown option using negotiator policy" {
  let transition = @telnet.Negotiator::new().receive(
    neg_event(@telnet.NegotiationVerb::Will, 201),
    @telnet.PolicyDecision::Reject,
  )
  assert_true(
    transition.after ==
    option_state(201, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(
    transition.actions ==
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 201),
      ),
    ],
  )
}

///|
test "docs example canonical encoder escapes data IAC" {
  let item = @telnet.EncodeItem::EscapedData(span([65, 255, 66]))
  let out = Bytes::new(@telnet.Encoder::canonical().required_capacity(item))
  match @telnet.Encoder::canonical().encode_item(item, out) {
    Ok(r) => {
      assert_true(r.bytes_written == 4)
      assert_true(out == bytes([65, 255, 255, 66]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "docs example incomplete input reports error on finish" {
  let partial = @telnet.Parser::default().feed(bytes([72, 105, 255, 253]))
  assert_true(partial.events == [data([72, 105])])
  let finished = partial.parser.finish()
  assert_true(finished.complete == false)
  assert_true(
    finished.events ==
    [err(@telnet.TelnetErrorKind::IncompleteNegotiation, 3, Some(253))],
  )
}

///|
test "docs example parse loop carries split negotiation state" {
  let mut parser = @telnet.Parser::default()
  let mut events : Array[@telnet.Event] = []
  [bytes([87, 105, 108, 108, 32]), bytes([255, 251]), bytes([1, 63])].each(fn(
    chunk,
  ) {
    let result = parser.feed(chunk)
    events = events + result.events
    parser = result.parser
  })
  assert_true(
    events_semantically_equal(events, [
      data([87, 105, 108, 108, 32]),
      neg(@telnet.NegotiationVerb::Will, 1),
      data([63]),
    ]),
  )
  assert_true(parser.finish().events == [])
}

///|
test "docs example encode negotiator reply action" {
  let transition = @telnet.Negotiator::new().receive(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Accept,
  )
  let wire = Bytes::new(3)
  match transition.actions[0] {
    @telnet.NegotiationAction::Send(reply) =>
      match
        @telnet.Encoder::canonical().encode_item(
          @telnet.EncodeItem::Negotiation(reply),
          wire,
        ) {
        Ok(r) => {
          assert_true(r.bytes_written == 3)
          assert_true(wire == bytes([255, 253, 1]))
        }
        Err(_) => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "docs example decode raw TERMINAL-TYPE subnegotiation" {
  let parsed = @telnet.Parser::default().feed(
    bytes([255, 250, 24, 0, 120, 116, 101, 114, 109, 255, 240]),
  )
  match parsed.events[0] {
    @telnet.Event::Subnegotiation(sb_event) =>
      match @telnet.OptionPayload::decode(sb_event.option, sb_event.payload) {
        Ok(
          @telnet.OptionPayload::TerminalType(
            @telnet.TerminalTypeMessage::Is(name)
          )
        ) => assert_true(name == "xterm")
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "docs example decode START_TLS and keep transport policy external" {
  let parsed = @telnet.Parser::default().feed(
    bytes([255, 250, 46, 1, 255, 240, 79, 75]),
  )
  assert_true(
    events_semantically_equal(parsed.events, [sb(46, [1]), data([79, 75])]),
  )
  match parsed.events[0] {
    @telnet.Event::Subnegotiation(sb_event) =>
      match @telnet.OptionPayload::decode(sb_event.option, sb_event.payload) {
        Ok(@telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows)) =>
          ()
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "docs example encode option payload then subnegotiation" {
  let payload = @telnet.OptionPayload::Naws(@telnet.NawsSize::{
    columns: (132).to_uint16(),
    rows: (43).to_uint16(),
  })
  let payload_out = Bytes::new(
    @telnet.OptionPayload::required_capacity(payload),
  )
  match @telnet.OptionPayload::encode(payload, payload_out) {
    Ok(p) => {
      assert_true(p.bytes_written == 4)
      let event = @telnet.SubnegotiationEvent::{
        option: opt(31),
        payload: @telnet.ByteSpan::new(payload_out, 0, p.bytes_written),
      }
      let wire = Bytes::new(
        @telnet.Encoder::canonical().required_capacity(
          @telnet.EncodeItem::Subnegotiation(event),
        ),
      )
      match @telnet.Encoder::canonical().encode_subnegotiation(event, wire) {
        Ok(r) => {
          assert_true(r.bytes_written == 9)
          assert_true(wire == bytes([255, 250, 31, 0, 132, 0, 43, 255, 240]))
        }
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}
