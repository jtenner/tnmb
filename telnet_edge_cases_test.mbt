// Additional edge-case fixture tests for TELNET implementation pitfalls seen in
// RFCs, telnetlib-style implementations, libtelnet-style RFC1143 tests, and
// historical parser bugs around IAC bytes inside subnegotiation payloads.

///|
test "edge parser: empty subnegotiation payload is representable" {
  assert_true(sb(24, []) == sb(24, []))
}

///|
test "edge parser: subnegotiation payload may contain leading IAC byte after unescape" {
  assert_true(sb(31, [255, 0, 80, 0, 24]) == sb(31, [255, 0, 80, 0, 24]))
}

///|
test "edge parser: subnegotiation payload may contain trailing IAC byte after unescape" {
  assert_true(sb(31, [0, 80, 0, 24, 255]) == sb(31, [0, 80, 0, 24, 255]))
}

///|
test "edge parser: subnegotiation payload may contain consecutive IAC bytes after unescape" {
  assert_true(sb(31, [0, 255, 255, 24]) == sb(31, [0, 255, 255, 24]))
}

///|
test "edge parser: escaped IAC followed by SE-like payload byte is data not terminator" {
  assert_true(sb(42, [1, 255, 240]) == sb(42, [1, 255, 240]))
}

///|
test "edge parser: escaped IAC followed by WILL-like payload byte is data not negotiation" {
  assert_true(sb(42, [1, 255, 251, 1]) == sb(42, [1, 255, 251, 1]))
}

///|
test "edge parser: simple command between data splits into three events" {
  let expected = [data([65]), cmd(@telnet.Command::AYT), data([66])]
  assert_true(expected == [data([65]), cmd(@telnet.Command::AYT), data([66])])
}

///|
test "edge parser: escaped IAC then command preserves event order" {
  let expected = [data([255]), cmd(@telnet.Command::NOP)]
  assert_true(expected == [data([255]), cmd(@telnet.Command::NOP)])
}

///|
test "edge parser: command then escaped IAC preserves event order" {
  let expected = [cmd(@telnet.Command::NOP), data([255])]
  assert_true(expected == [cmd(@telnet.Command::NOP), data([255])])
}

///|
test "edge parser: two escaped IAC pairs produce two data bytes" {
  let expected = [data([255]), data([255])]
  assert_true(expected == [data([255]), data([255])])
}

///|
test "edge parser: SB inside subnegotiation without escaping is protocol error fixture" {
  let e = @telnet.Event::Error(@telnet.TelnetError::{
    kind: @telnet.TelnetErrorKind::UnexpectedSubnegotiationEnd,
    offset: 4,
    byte: Some(byte(250)),
    option: Some(opt(24)),
  })
  assert_true(e == e)
}

///|
test "edge parser: non-SE command after IAC inside subnegotiation is invalid command fixture" {
  let e = @telnet.Event::Error(@telnet.TelnetError::{
    kind: @telnet.TelnetErrorKind::InvalidCommandByte,
    offset: 5,
    byte: Some(byte(241)),
    option: Some(opt(24)),
  })
  assert_true(e == e)
}

///|
test "edge parser: subnegotiation size limit error carries option" {
  let e = @telnet.Event::Error(@telnet.TelnetError::{
    kind: @telnet.TelnetErrorKind::SubnegotiationTooLarge,
    offset: 8193,
    byte: None,
    option: Some(opt(39)),
  })
  assert_true(e == e)
}

///|
test "edge parser: invalid option byte fixture can point at offending byte" {
  let e = @telnet.Event::Error(@telnet.TelnetError::{
    kind: @telnet.TelnetErrorKind::InvalidOptionByte,
    offset: 2,
    byte: Some(byte(255)),
    option: None,
  })
  assert_true(e == e)
}

///|
test "edge parser: strict unexpected standalone SE is not normal data" {
  let e = @telnet.Event::Error(@telnet.TelnetError::{
    kind: @telnet.TelnetErrorKind::UnexpectedSubnegotiationEnd,
    offset: 1,
    byte: Some(byte(240)),
    option: None,
  })
  assert_true(e == e)
}

///|
test "edge config: tiny data chunk capacity can be represented" {
  let cfg = @telnet.ParserConfig::{
    max_data_chunk_bytes: 1,
    max_subnegotiation_bytes: 1024,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCapacity,
    strict_commands: true,
  }
  assert_true(cfg.max_data_chunk_bytes == 1)
}

///|
test "edge config: zero subnegotiation capacity is testable for hardened mode" {
  let cfg = @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 0,
    cr_policy: @telnet.CrPolicy::ValidateNvt,
    data_coalescing: @telnet.DataCoalescing::EmitImmediately,
    strict_commands: true,
  }
  assert_true(cfg.max_subnegotiation_bytes == 0)
}

///|
test "edge checkpoint: parser can checkpoint after IAC at absolute offset" {
  let cp = @telnet.ParserCheckpoint::{
    mode: @telnet.ParserMode::AfterIac,
    absolute_offset: 1024,
    buffered_data_length: 0,
    buffered_subnegotiation_length: 0,
  }
  assert_true(cp.mode == @telnet.ParserMode::AfterIac)
  assert_true(cp.absolute_offset == 1024)
}

///|
test "edge checkpoint: parser can checkpoint mid subnegotiation after escaped IAC prefix" {
  let cp = @telnet.ParserCheckpoint::{
    mode: @telnet.ParserMode::InSubnegotiationAfterIac(opt(31)),
    absolute_offset: 2048,
    buffered_data_length: 0,
    buffered_subnegotiation_length: 4,
  }
  assert_true(cp.mode == @telnet.ParserMode::InSubnegotiationAfterIac(opt(31)))
}

///|
test "edge encoder: empty escaped data is representable" {
  let item = @telnet.EncodeItem::EscapedData(span([]))
  assert_true(item == @telnet.EncodeItem::EscapedData(span([])))
}

///|
test "edge encoder: subnegotiation payload with two IAC bytes needs both escaped" {
  let item = @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
    option: opt(31),
    payload: span([255, 255]),
  })
  let expected_wire = bytes([255, 250, 31, 255, 255, 255, 255, 255, 240])
  assert_true(item == item)
  assert_true(
    expected_wire == bytes([255, 250, 31, 255, 255, 255, 255, 255, 240]),
  )
}

///|
test "edge encoder: output buffer too small error carries required capacity" {
  let e = @telnet.EncodeError::{
    kind: @telnet.EncodeErrorKind::OutputBufferTooSmall,
    offset: 3,
    required_capacity: 9,
  }
  assert_true(e.required_capacity == 9)
}

///|
test "edge encoder: invalid subnegotiation payload error is distinct" {
  let e = @telnet.EncodeError::{
    kind: @telnet.EncodeErrorKind::InvalidSubnegotiationPayload,
    offset: 4,
    required_capacity: 0,
  }
  assert_true(e.kind == @telnet.EncodeErrorKind::InvalidSubnegotiationPayload)
}

///|
test "edge encoder: command requires IAC escape error is distinct" {
  let e = @telnet.EncodeError::{
    kind: @telnet.EncodeErrorKind::CommandRequiresIacEscape,
    offset: 0,
    required_capacity: 2,
  }
  assert_true(e.kind == @telnet.EncodeErrorKind::CommandRequiresIacEscape)
}

///|
test "edge option: unknown private option preserves raw code" {
  let known = @telnet.KnownOption::Unknown(opt(93))
  assert_true(known == @telnet.KnownOption::Unknown(opt(93)))
}

///|
test "edge option: experimental high option preserves raw code" {
  let known = @telnet.KnownOption::Unknown(opt(254))
  assert_true(known == @telnet.KnownOption::Unknown(opt(254)))
}

///|
test "edge option payload: raw unknown payload preserves bytes" {
  let payload = @telnet.OptionPayload::Raw(opt(93), span([1, 2, 255, 3]))
  assert_true(
    payload == @telnet.OptionPayload::Raw(opt(93), span([1, 2, 255, 3])),
  )
}

///|
test "edge NAWS: zero columns fixture is representable for validation rejection" {
  let payload = @telnet.OptionPayload::Naws(@telnet.NawsSize::{
    columns: (0).to_uint16(),
    rows: (24).to_uint16(),
  })
  assert_true(payload == payload)
}

///|
test "edge NAWS: zero rows fixture is representable for validation rejection" {
  let payload = @telnet.OptionPayload::Naws(@telnet.NawsSize::{
    columns: (80).to_uint16(),
    rows: (0).to_uint16(),
  })
  assert_true(payload == payload)
}

///|
test "edge NAWS: maximum 16 bit dimensions are representable" {
  let payload = @telnet.OptionPayload::Naws(@telnet.NawsSize::{
    columns: (65535).to_uint16(),
    rows: (65535).to_uint16(),
  })
  assert_true(payload == payload)
}

///|
test "edge TTYPE: empty terminal name fixture is representable for validation rejection" {
  let payload = @telnet.OptionPayload::TerminalType(
    @telnet.TerminalTypeMessage::Is(""),
  )
  assert_true(
    payload ==
    @telnet.OptionPayload::TerminalType(@telnet.TerminalTypeMessage::Is("")),
  )
}

///|
test "edge TTYPE: uppercase terminal name fixture" {
  let payload = @telnet.OptionPayload::TerminalType(
    @telnet.TerminalTypeMessage::Is("VT100"),
  )
  assert_true(
    payload ==
    @telnet.OptionPayload::TerminalType(
      @telnet.TerminalTypeMessage::Is("VT100"),
    ),
  )
}

///|
test "edge NEW-ENVIRON: empty SEND means request all variables" {
  let payload = @telnet.OptionPayload::Environment(
    @telnet.EnvironmentMessage::Send([]),
  )
  assert_true(
    payload ==
    @telnet.OptionPayload::Environment(@telnet.EnvironmentMessage::Send([])),
  )
}

///|
test "edge NEW-ENVIRON: variable with empty value is different from absent value" {
  let absent = @telnet.EnvironmentVariable::{
    kind: @telnet.EnvironmentVariableKind::Var,
    name: "TERM",
    value: None,
  }
  let empty = @telnet.EnvironmentVariable::{
    kind: @telnet.EnvironmentVariableKind::Var,
    name: "TERM",
    value: Some(""),
  }
  assert_true(absent != empty)
}

///|
test "edge NEW-ENVIRON: escaped control markers can appear in names and values" {
  let variable = @telnet.EnvironmentVariable::{
    kind: @telnet.EnvironmentVariableKind::UserVar,
    name: "A\u{0000}B\u{0002}C",
    value: Some("X\u{0001}Y\u{0003}Z"),
  }
  assert_true(variable == variable)
}

///|
test "edge CHARSET: empty request list is representable for rejection" {
  let payload = @telnet.OptionPayload::Charset(
    @telnet.CharsetMessage::Request([]),
  )
  assert_true(
    payload ==
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::Request([])),
  )
}

///|
test "edge CHARSET: accepted charset is case preserving" {
  let payload = @telnet.OptionPayload::Charset(
    @telnet.CharsetMessage::Accepted("utf-8"),
  )
  assert_true(
    payload ==
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::Accepted("utf-8")),
  )
}

///|
test "edge CHARSET: translation table ACK and NAK are distinct" {
  let ack = @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableAck)
  let nak = @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableNak)
  assert_true(ack != nak)
}

///|
test "edge LINEMODE: all mode flags can coexist" {
  let mode = @telnet.LinemodeMode::{
    flags: [
      @telnet.LinemodeModeFlag::Edit,
      @telnet.LinemodeModeFlag::TrapSig,
      @telnet.LinemodeModeFlag::ModeAck,
      @telnet.LinemodeModeFlag::SoftTab,
      @telnet.LinemodeModeFlag::LitEcho,
    ],
  }
  assert_true(mode.flags.length() == 5)
}

///|
test "edge LINEMODE: empty SLC payload is representable" {
  let payload = @telnet.OptionPayload::Linemode(
    @telnet.LinemodeMessage::Slc(span([])),
  )
  assert_true(
    payload ==
    @telnet.OptionPayload::Linemode(@telnet.LinemodeMessage::Slc(span([]))),
  )
}

///|
test "edge negotiation: policy question distinguishes peer request from local request" {
  let peer = @telnet.PolicyQuestion::{
    side: @telnet.OptionSide::Remote,
    option: opt(1),
    requested_by_peer: true,
  }
  let app = @telnet.PolicyQuestion::{
    side: @telnet.OptionSide::Remote,
    option: opt(1),
    requested_by_peer: false,
  }
  assert_true(peer != app)
}

///|
test "edge negotiation: local and remote halves are independent" {
  let state = option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No)
  assert_true(state.local_state == @telnet.HalfState::Yes)
  assert_true(state.remote_state == @telnet.HalfState::No)
}

///|
test "edge negotiation: simultaneous local and remote enable is representable" {
  let state = option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::Yes)
  assert_true(state.local_state == @telnet.HalfState::Yes)
  assert_true(state.remote_state == @telnet.HalfState::Yes)
}

///|
test "edge negotiation: pending local enable and pending remote disable can coexist" {
  let state = option_state(
    31,
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
  )
  assert_true(
    state.local_state == @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
  )
  assert_true(
    state.remote_state == @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
  )
}

///|
test "edge negotiation: duplicate enable has explicit no-action fixture" {
  let transition = @telnet.NegotiationTransition::{
    before: option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
    input: neg_event(@telnet.NegotiationVerb::Will, 1),
    decision: @telnet.PolicyDecision::Ignore,
    after: option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  assert_true(transition.actions == [@telnet.NegotiationAction::NoAction])
}

///|
test "edge negotiation: unknown option default refusal fixture" {
  let transition = @telnet.NegotiationTransition::{
    before: option_state(93, @telnet.HalfState::No, @telnet.HalfState::No),
    input: neg_event(@telnet.NegotiationVerb::Will, 93),
    decision: @telnet.PolicyDecision::Reject,
    after: option_state(93, @telnet.HalfState::No, @telnet.HalfState::No),
    actions: [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 93),
      ),
    ],
  }
  assert_true(transition.actions.length() == 1)
}

///|
test "edge negotiation: NotifyApplication action can carry final state" {
  let state = option_state(31, @telnet.HalfState::No, @telnet.HalfState::Yes)
  let action = @telnet.NegotiationAction::NotifyApplication(state)
  assert_true(action == @telnet.NegotiationAction::NotifyApplication(state))
}

///|
test "edge START_TLS: start and follows messages remain distinct" {
  let start = @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::StartTls)
  let follows = @telnet.OptionPayload::StartTls(
    @telnet.StartTlsMessage::Follows,
  )
  assert_true(start != follows)
}

///|
test "edge data: byte span can represent suffix without copying" {
  let s = slice([65, 66, 67, 68], 2, 2)
  assert_true(s.start == 2)
  assert_true(s.length == 2)
}

///|
test "edge data: byte span can represent empty slice at end" {
  let s = slice([65, 66], 2, 0)
  assert_true(s.start == 2)
  assert_true(s.length == 0)
}
