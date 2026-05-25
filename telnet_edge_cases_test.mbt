// Additional edge-case tests for parser framing, encoder escaping, option codecs,
// and negotiation behavior.

///|
fn assert_edge_parse(
  wire : Array[Int],
  expected : Array[@telnet.Event],
) -> Unit raise {
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.events == expected)
  assert_true(result.bytes_consumed == wire.length())
}

///|
fn assert_edge_parse_config(
  config : @telnet.ParserConfig,
  wire : Array[Int],
  expected : Array[@telnet.Event],
) -> Unit raise {
  let result = @telnet.Parser::new(config).feed(bytes(wire))
  assert_true(result.events == expected)
  assert_true(result.bytes_consumed == wire.length())
}

///|
fn assert_edge_encoded(
  item : @telnet.EncodeItem,
  expected : Array[Int],
) -> Unit raise {
  let output = Bytes::new(expected.length())
  match @telnet.Encoder::canonical().encode_item(item, output) {
    Ok(r) => {
      assert_true(r.bytes_written == expected.length())
      assert_true(output == bytes(expected))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "edge parser handles unusual subnegotiation payload IAC placement" {
  assert_edge_parse([255, 250, 24, 255, 240], [sb(24, [])])
  assert_edge_parse([255, 250, 31, 255, 255, 0, 80, 0, 24, 255, 240], [
    sb(31, [255, 0, 80, 0, 24]),
  ])
  assert_edge_parse([255, 250, 31, 0, 80, 0, 24, 255, 255, 255, 240], [
    sb(31, [0, 80, 0, 24, 255]),
  ])
  assert_edge_parse([255, 250, 31, 0, 255, 255, 255, 255, 24, 255, 240], [
    sb(31, [0, 255, 255, 24]),
  ])
  assert_edge_parse([255, 250, 42, 1, 255, 255, 240, 255, 240], [
    sb(42, [1, 255, 240]),
  ])
  assert_edge_parse([255, 250, 42, 1, 255, 255, 251, 1, 255, 240], [
    sb(42, [1, 255, 251, 1]),
  ])
}

///|
test "edge parser preserves event order around commands and escaped IAC" {
  assert_edge_parse([65, 255, 246, 66], [
    data([65]),
    cmd(@telnet.Command::AYT),
    data([66]),
  ])
  let finished = @telnet.Parser::default().feed(bytes([65, 255, 246, 66])).parser.finish()
  assert_true(finished.events == [])
  assert_edge_parse([255, 255, 255, 241], [
    data([255]),
    cmd(@telnet.Command::NOP),
  ])
  assert_edge_parse([255, 241, 255, 255], [
    cmd(@telnet.Command::NOP),
    data([255]),
  ])
  assert_edge_parse([255, 255, 255, 255], [data([255]), data([255])])
}

///|
test "edge parser reports protocol errors with offsets and options" {
  assert_edge_parse([255, 250, 24, 1, 255, 250], [
    @telnet.Event::Error(@telnet.TelnetError::{
      kind: @telnet.TelnetErrorKind::InvalidCommandByte,
      offset: 5,
      byte: Some(byte(250)),
      option: None,
    }),
  ])
  assert_edge_parse([255, 250, 24, 1, 255, 241], [
    @telnet.Event::Error(@telnet.TelnetError::{
      kind: @telnet.TelnetErrorKind::InvalidCommandByte,
      offset: 5,
      byte: Some(byte(241)),
      option: None,
    }),
  ])
  assert_edge_parse([255, 240], [
    err(@telnet.TelnetErrorKind::UnexpectedSubnegotiationEnd, 1, Some(240)),
  ])
  let tiny = @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 0,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
  assert_edge_parse_config(tiny, [255, 250, 39, 1], [
    @telnet.Event::Error(@telnet.TelnetError::{
      kind: @telnet.TelnetErrorKind::SubnegotiationTooLarge,
      offset: 3,
      byte: Some(byte(1)),
      option: None,
    }),
  ])
}

///|
test "edge encoder handles empty data, escaped subnegotiation IACs, and capacity errors" {
  assert_edge_encoded(@telnet.EncodeItem::EscapedData(span([])), [])
  assert_edge_encoded(
    @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([255, 255]),
    }),
    [255, 250, 31, 255, 255, 255, 255, 255, 240],
  )
  let output = Bytes::new(3)
  match
    @telnet.Encoder::canonical().encode_item(
      @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: opt(31),
        payload: span([255, 255]),
      }),
      output,
    ) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      assert_true(e.required_capacity == 9)
    }
  }
}

///|
test "edge option mapping and payload codecs exercise boundary values" {
  assert_true(
    @telnet.KnownOption::from_code(opt(93)) ==
    @telnet.KnownOption::Unknown(opt(93)),
  )
  assert_true(
    @telnet.KnownOption::from_code(opt(254)) ==
    @telnet.KnownOption::Unknown(opt(254)),
  )
  match @telnet.NawsSize::decode(span([0, 0, 0, 24])) {
    Ok(size) => {
      assert_true(size.columns == (0).to_uint16())
      assert_true(size.rows == (24).to_uint16())
    }
    Err(_) => assert_true(false)
  }
  match @telnet.NawsSize::decode(span([255, 255, 255, 255])) {
    Ok(size) => {
      assert_true(size.columns == (65535).to_uint16())
      assert_true(size.rows == (65535).to_uint16())
    }
    Err(_) => assert_true(false)
  }
  match @telnet.TerminalTypeMessage::decode(span([0])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::PolicyRejected)
  }
  match @telnet.TerminalTypeMessage::decode(span([0, 86, 84, 49, 48, 48])) {
    Ok(msg) => assert_true(msg == @telnet.TerminalTypeMessage::Is("VT100"))
    Err(_) => assert_true(false)
  }
  match @telnet.CharsetMessage::decode(span([1])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::PolicyRejected)
  }
}

///|
test "edge environment and linemode values roundtrip through codecs" {
  let env = @telnet.EnvironmentMessage::Is([
    @telnet.EnvironmentVariable::{
      kind: @telnet.EnvironmentVariableKind::UserVar,
      name: "TERM",
      value: Some("xterm-256color"),
    },
  ])
  let env_out = Bytes::new(128)
  match @telnet.EnvironmentMessage::encode(env, env_out) {
    Ok(r) =>
      match
        @telnet.EnvironmentMessage::decode(
          @telnet.ByteSpan::new(env_out, 0, r.bytes_written),
        ) {
        Ok(decoded) => assert_true(decoded == env)
        Err(_) => assert_true(false)
      }
    Err(_) => assert_true(false)
  }
  let mode = @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
    flags: [
      @telnet.LinemodeModeFlag::Edit,
      @telnet.LinemodeModeFlag::TrapSig,
      @telnet.LinemodeModeFlag::ModeAck,
      @telnet.LinemodeModeFlag::SoftTab,
      @telnet.LinemodeModeFlag::LitEcho,
    ],
  })
  let mode_out = Bytes::new(16)
  match @telnet.LinemodeMessage::encode(mode, mode_out) {
    Ok(r) =>
      match
        @telnet.LinemodeMessage::decode(
          @telnet.ByteSpan::new(mode_out, 0, r.bytes_written),
        ) {
        Ok(decoded) => assert_true(decoded == mode)
        Err(_) => assert_true(false)
      }
    Err(_) => assert_true(false)
  }
}

///|
test "edge negotiator and byte spans exercise real APIs" {
  let duplicate = @telnet.Negotiator::with_states([
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
  ]).receive(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Ignore,
  )
  assert_true(duplicate.actions == [@telnet.NegotiationAction::NoAction])
  let unknown = @telnet.Negotiator::new().receive(
    neg_event(@telnet.NegotiationVerb::Will, 93),
    @telnet.PolicyDecision::Reject,
  )
  assert_true(
    unknown.actions ==
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 93),
      ),
    ],
  )
  assert_true(slice([65, 66, 67, 68], 2, 2).to_bytes() == bytes([67, 68]))
  assert_true(slice([65, 66], 2, 0).to_bytes() == bytes([]))
}
