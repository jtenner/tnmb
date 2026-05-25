// Session-level boundary characterization. The core has no Session type yet, so
// these tests prove raw parser/codec behavior remains transport-independent.

///|
test "session boundary BINARY negotiation does not mutate parser CR policy" {
  let config = @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::ValidateNvt,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
  let parser = @telnet.Parser::new(config)
  let binary = parser.feed(bytes([255, 251, 0]))
  assert_true(binary.events == [neg(@telnet.NegotiationVerb::Will, 0)])
  let cr = binary.parser.feed(bytes([13, 88]))
  assert_true(
    cr.events ==
    [err(@telnet.TelnetErrorKind::PolicyRejected, 4, Some(88)), data([88])],
  )
}

///|
test "session boundary START_TLS FOLLOWS does not enforce transport security in parser" {
  let parser = @telnet.Parser::default()
  let follows = parser.feed(bytes([255, 250, 46, 1, 255, 240]))
  assert_true(follows.events == [sb(46, [1])])
  match restored_payload_at(follows.events, 0) {
    @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows) => ()
    _ => assert_true(false)
  }
  let plaintext = follows.parser.feed(bytes([65, 66]))
  assert_true(plaintext.events == [data([65, 66])])
}

///|
test "session boundary application can derive decoded option payload from raw SB" {
  let parsed = @telnet.Parser::default().feed(
    bytes([255, 250, 31, 0, 80, 0, 24, 255, 240]),
  )
  match parsed.events[0] {
    @telnet.Event::Subnegotiation(sb) =>
      match @telnet.OptionPayload::decode(sb.option, sb.payload) {
        Ok(@telnet.OptionPayload::Naws(size)) => {
          assert_true(size.columns == (80).to_uint16())
          assert_true(size.rows == (24).to_uint16())
        }
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "session boundary AUTHENTICATION and ENCRYPTION remain raw unsupported payloads" {
  match @telnet.OptionPayload::decode(opt(37), span([1, 2, 3])) {
    Ok(payload) =>
      assert_true(
        payload == @telnet.OptionPayload::Raw(opt(37), span([1, 2, 3])),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.OptionPayload::decode(opt(38), span([4, 5, 6])) {
    Ok(payload) =>
      assert_true(
        payload == @telnet.OptionPayload::Raw(opt(38), span([4, 5, 6])),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "session boundary application combines parser negotiator codec and encoder externally" {
  let parsed = @telnet.Parser::default().feed(
    bytes([255, 251, 24, 255, 250, 24, 1, 255, 240]),
  )
  assert_true(parsed.events.length() == 2)
  match parsed.events[0] {
    @telnet.Event::Negotiation(e) => {
      let transition = @telnet.Negotiator::new().receive(
        e,
        @telnet.PolicyDecision::Accept,
      )
      assert_true(
        transition.actions ==
        [
          @telnet.NegotiationAction::Send(
            neg_event(@telnet.NegotiationVerb::Do, 24),
          ),
          @telnet.NegotiationAction::MarkEnabled(
            @telnet.OptionSide::Remote,
            opt(24),
          ),
        ],
      )
      let out = Bytes::new(3)
      match
        @telnet.Encoder::canonical().encode_item(
          @telnet.EncodeItem::Negotiation(
            neg_event(@telnet.NegotiationVerb::Do, 24),
          ),
          out,
        ) {
        Ok(r) => {
          assert_true(r.bytes_written == 3)
          assert_true(out == bytes([255, 253, 24]))
        }
        Err(_) => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
  match parsed.events[1] {
    @telnet.Event::Subnegotiation(sb) =>
      match @telnet.OptionPayload::decode(sb.option, sb.payload) {
        Ok(
          @telnet.OptionPayload::TerminalType(@telnet.TerminalTypeMessage::Send)
        ) => ()
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "session boundary START_TLS plaintext blocking is an application decision" {
  let parsed = @telnet.Parser::default().feed(
    bytes([255, 250, 46, 1, 255, 240, 65, 66]),
  )
  assert_true(parsed.events == [sb(46, [1]), data([65, 66])])
  let mut app_requires_tls_upgrade = false
  match restored_payload_at(parsed.events, 0) {
    @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows) =>
      app_requires_tls_upgrade = true
    _ => assert_true(false)
  }
  assert_true(app_requires_tls_upgrade)
}

///|
test "session boundary BINARY accept on both directions still leaves parser policy external" {
  let negotiator = @telnet.Negotiator::new()
  let remote = negotiator.receive(
    neg_event(@telnet.NegotiationVerb::Will, 0),
    @telnet.PolicyDecision::Accept,
  )
  let after_remote = negotiator.apply(remote)
  let local_transition = after_remote.receive(
    neg_event(@telnet.NegotiationVerb::Do, 0),
    @telnet.PolicyDecision::Accept,
  )
  let after_both = after_remote.apply(local_transition)
  assert_true(
    after_both.state_for(opt(0)).remote_state == @telnet.HalfState::Yes,
  )
  assert_true(
    after_both.state_for(opt(0)).local_state == @telnet.HalfState::Yes,
  )

  let validate_parser = @telnet.Parser::new(@telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::ValidateNvt,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  })
  let invalid_cr = validate_parser.feed(bytes([13, 88]))
  assert_true(
    invalid_cr.events ==
    [err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(88)), data([88])],
  )
}

///|
test "session boundary START_TLS request and follows are just decoded payloads" {
  let request = @telnet.Parser::default().feed(
    bytes([255, 250, 46, 0, 255, 240]),
  )
  let follows = request.parser.feed(bytes([255, 250, 46, 1, 255, 240, 80]))
  assert_true(request.events == [sb(46, [0])])
  assert_true(follows.events == [sb(46, [1]), data([80])])
  assert_true(
    restored_payload_at(request.events, 0) ==
    @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::StartTls),
  )
  assert_true(
    restored_payload_at(follows.events, 0) ==
    @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows),
  )
}
