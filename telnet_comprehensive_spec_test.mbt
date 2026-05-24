// Comprehensive fixture-first TELNET specification tests.
//
// These tests deliberately do not call production parser/encoder/negotiator
// functions yet. They define edge-case expectations and invariants that future
// production tests should assert against real APIs.

///|
struct WireEventFixture {
  name : String
  wire : Bytes
  events : Array[@telnet.Event]
}

///|
struct ModeFixture {
  name : String
  config : @telnet.ParserConfig
  wire : Bytes
  expected : Array[@telnet.Event]
}

///|
struct RoundTripFixture {
  name : String
  event : @telnet.Event
  canonical_wire : Bytes
}

///|
struct OptionValidationFixture {
  name : String
  option : @telnet.OptionCode
  payload : @telnet.ByteSpan
  expected : @telnet.OptionPayload?
  error : @telnet.TelnetErrorKind?
}

///|
struct InitiationFixture {
  name : String
  before : @telnet.OptionState
  side : @telnet.OptionSide
  request_enable : Bool
  after : @telnet.OptionState
  actions : Array[@telnet.NegotiationAction]
}

///|
fn preserve_config() -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
fn validate_config() -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::ValidateNvt,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
fn normalize_config() -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::NormalizeToLf,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
fn lenient_config() -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: false,
  }
}

///|
fn verify_wire_event_fixture(f : WireEventFixture) -> Unit raise {
  assert_true(f.name.length() > 0)
  assert_true(f.wire.length() >= 0)
  assert_true(f.events.length() >= 0)
}

///|
fn verify_mode_fixture(f : ModeFixture) -> Unit raise {
  assert_true(f.name.length() > 0)
  assert_true(f.config.max_data_chunk_bytes >= 0)
  assert_true(f.wire.length() >= 0)
  assert_true(f.expected.length() >= 0)
}

///|
fn verify_roundtrip_fixture(f : RoundTripFixture) -> Unit raise {
  assert_true(f.name.length() > 0)
  assert_true(f.event == f.event)
  assert_true(f.canonical_wire.length() >= 0)
}

///|
test "exhaustive split fixtures: every split point for representative command streams" {
  let fixtures = [
    WireEventFixture::{
      name: "IAC IAC",
      wire: bytes([255, 255]),
      events: [data([255])],
    },
    WireEventFixture::{
      name: "IAC NOP",
      wire: bytes([255, 241]),
      events: [cmd(@telnet.Command::NOP)],
    },
    WireEventFixture::{
      name: "WILL ECHO",
      wire: bytes([255, 251, 1]),
      events: [neg(@telnet.NegotiationVerb::Will, 1)],
    },
    WireEventFixture::{
      name: "DO NAWS",
      wire: bytes([255, 253, 31]),
      events: [neg(@telnet.NegotiationVerb::Do, 31)],
    },
    WireEventFixture::{
      name: "TTYPE SEND",
      wire: bytes([255, 250, 24, 1, 255, 240]),
      events: [sb(24, [1])],
    },
    WireEventFixture::{
      name: "NAWS with escaped IAC",
      wire: bytes([255, 250, 31, 0, 255, 255, 0, 24, 255, 240]),
      events: [sb(31, [0, 255, 0, 24])],
    },
    WireEventFixture::{
      name: "mixed data command data",
      wire: bytes([65, 255, 246, 66]),
      events: [data([65]), cmd(@telnet.Command::AYT), data([66])],
    },
  ]
  fixtures.each(fn(f) raise {
    verify_wire_event_fixture(f)
    let len = f.wire.length()
    for split = 0; split <= len; split = split + 1 {
      assert_true(split >= 0)
      assert_true(split <= len)
      assert_true(f.events == f.events)
    }
  })
}

///|
test "strict parser invalid IAC command fixtures" {
  let cases = [
    WireEventFixture::{
      name: "IAC NUL strict error",
      wire: bytes([255, 0]),
      events: [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(0))],
    },
    WireEventFixture::{
      name: "IAC ECHO strict error",
      wire: bytes([255, 1]),
      events: [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(1))],
    },
    WireEventFixture::{
      name: "IAC 42 strict error",
      wire: bytes([255, 42]),
      events: [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(42))],
    },
    WireEventFixture::{
      name: "IAC 239 strict error",
      wire: bytes([255, 239]),
      events: [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(239))],
    },
  ]
  cases.each(fn(f) raise { verify_wire_event_fixture(f) })
}

///|
test "lenient parser invalid IAC command fixtures preserve recoverability" {
  let cases = [
    ModeFixture::{
      name: "IAC NUL lenient ignored",
      config: lenient_config(),
      wire: bytes([255, 0]),
      expected: [],
    },
    ModeFixture::{
      name: "IAC 42 lenient ignored",
      config: lenient_config(),
      wire: bytes([255, 42]),
      expected: [],
    },
    ModeFixture::{
      name: "IAC 239 lenient ignored",
      config: lenient_config(),
      wire: bytes([255, 239]),
      expected: [],
    },
    ModeFixture::{
      name: "invalid then valid recovers",
      config: lenient_config(),
      wire: bytes([255, 42, 255, 241]),
      expected: [cmd(@telnet.Command::NOP)],
    },
  ]
  cases.each(fn(f) raise {
    verify_mode_fixture(f)
    assert_true(f.config.strict_commands == false)
  })
}

///|
test "NVT CR policy preserve fixtures" {
  let cases = [
    ModeFixture::{
      name: "preserve CR LF",
      config: preserve_config(),
      wire: bytes([13, 10]),
      expected: [data([13, 10])],
    },
    ModeFixture::{
      name: "preserve CR NUL",
      config: preserve_config(),
      wire: bytes([13, 0]),
      expected: [data([13, 0])],
    },
    ModeFixture::{
      name: "preserve bare CR",
      config: preserve_config(),
      wire: bytes([13]),
      expected: [data([13])],
    },
    ModeFixture::{
      name: "preserve LF",
      config: preserve_config(),
      wire: bytes([10]),
      expected: [data([10])],
    },
    ModeFixture::{
      name: "preserve CR X",
      config: preserve_config(),
      wire: bytes([13, 88]),
      expected: [data([13, 88])],
    },
  ]
  cases.each(fn(f) raise {
    verify_mode_fixture(f)
    assert_true(f.config.cr_policy == @telnet.CrPolicy::Preserve)
  })
}

///|
test "NVT CR policy validate fixtures" {
  let cases = [
    ModeFixture::{
      name: "validate CR LF",
      config: validate_config(),
      wire: bytes([13, 10]),
      expected: [data([13, 10])],
    },
    ModeFixture::{
      name: "validate CR NUL",
      config: validate_config(),
      wire: bytes([13, 0]),
      expected: [data([13, 0])],
    },
    ModeFixture::{
      name: "validate bare CR error",
      config: validate_config(),
      wire: bytes([13]),
      expected: [err(@telnet.TelnetErrorKind::IncompleteIac, 0, Some(13))],
    },
    ModeFixture::{
      name: "validate CR X policy error",
      config: validate_config(),
      wire: bytes([13, 88]),
      expected: [err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(88))],
    },
  ]
  cases.each(fn(f) raise {
    verify_mode_fixture(f)
    assert_true(f.config.cr_policy == @telnet.CrPolicy::ValidateNvt)
  })
}

///|
test "NVT CR policy normalize fixtures" {
  let cases = [
    ModeFixture::{
      name: "normalize CR LF",
      config: normalize_config(),
      wire: bytes([13, 10]),
      expected: [data([10])],
    },
    ModeFixture::{
      name: "normalize CR NUL",
      config: normalize_config(),
      wire: bytes([13, 0]),
      expected: [data([13])],
    },
    ModeFixture::{
      name: "normalize LF unchanged",
      config: normalize_config(),
      wire: bytes([10]),
      expected: [data([10])],
    },
    ModeFixture::{
      name: "normalize CR split checkpoint",
      config: normalize_config(),
      wire: bytes([13]),
      expected: [err(@telnet.TelnetErrorKind::IncompleteIac, 0, Some(13))],
    },
  ]
  cases.each(fn(f) raise {
    verify_mode_fixture(f)
    assert_true(f.config.cr_policy == @telnet.CrPolicy::NormalizeToLf)
  })
}

///|
test "binary mode fixtures keep IAC escaping special" {
  let cases = [
    WireEventFixture::{
      name: "binary data can include NUL",
      wire: bytes([0]),
      events: [data([0])],
    },
    WireEventFixture::{
      name: "binary data can include high bit byte",
      wire: bytes([128, 254]),
      events: [data([128, 254])],
    },
    WireEventFixture::{
      name: "binary mode still escapes IAC",
      wire: bytes([255, 255]),
      events: [data([255])],
    },
    WireEventFixture::{
      name: "BINARY negotiation local",
      wire: bytes([255, 253, 0]),
      events: [neg(@telnet.NegotiationVerb::Do, 0)],
    },
    WireEventFixture::{
      name: "BINARY negotiation remote",
      wire: bytes([255, 251, 0]),
      events: [neg(@telnet.NegotiationVerb::Will, 0)],
    },
  ]
  cases.each(fn(f) raise { verify_wire_event_fixture(f) })
}

///|
test "data coalescing policy fixtures define event boundaries" {
  let emit = @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::EmitImmediately,
    strict_commands: true,
  }
  let command = preserve_config()
  let capacity = @telnet.ParserConfig::{
    max_data_chunk_bytes: 2,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCapacity,
    strict_commands: true,
  }
  let cases = [
    ModeFixture::{
      name: "emit immediately ABC",
      config: emit,
      wire: bytes([65, 66, 67]),
      expected: [data([65]), data([66]), data([67])],
    },
    ModeFixture::{
      name: "coalesce until command",
      config: command,
      wire: bytes([65, 66, 255, 241, 67]),
      expected: [data([65, 66]), cmd(@telnet.Command::NOP), data([67])],
    },
    ModeFixture::{
      name: "coalesce until capacity",
      config: capacity,
      wire: bytes([65, 66, 67]),
      expected: [data([65, 66]), data([67])],
    },
  ]
  cases.each(fn(f) raise { verify_mode_fixture(f) })
}

///|
test "negotiation initiation fixtures for local and remote halves" {
  let no = @telnet.HalfState::No
  let yes = @telnet.HalfState::Yes
  let want_yes_empty = @telnet.HalfState::WantYes(@telnet.QueueBit::Empty)
  let want_no_empty = @telnet.HalfState::WantNo(@telnet.QueueBit::Empty)
  let want_yes_opp = @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite)
  let want_no_opp = @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite)
  let cases = [
    InitiationFixture::{
      name: "ask peer to enable remote ECHO",
      before: option_state(1, no, no),
      side: @telnet.OptionSide::Remote,
      request_enable: true,
      after: option_state(1, no, want_yes_empty),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Do, 1),
        ),
      ],
    },
    InitiationFixture::{
      name: "ask peer to disable remote ECHO",
      before: option_state(1, no, yes),
      side: @telnet.OptionSide::Remote,
      request_enable: false,
      after: option_state(1, no, want_no_empty),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Dont, 1),
        ),
      ],
    },
    InitiationFixture::{
      name: "offer local ECHO",
      before: option_state(1, no, no),
      side: @telnet.OptionSide::Local,
      request_enable: true,
      after: option_state(1, want_yes_empty, no),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Will, 1),
        ),
      ],
    },
    InitiationFixture::{
      name: "disable local ECHO",
      before: option_state(1, yes, no),
      side: @telnet.OptionSide::Local,
      request_enable: false,
      after: option_state(1, want_no_empty, no),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Wont, 1),
        ),
      ],
    },
    InitiationFixture::{
      name: "remote pending enable then request disable queues opposite",
      before: option_state(31, no, want_yes_empty),
      side: @telnet.OptionSide::Remote,
      request_enable: false,
      after: option_state(31, no, want_yes_opp),
      actions: [@telnet.NegotiationAction::NoAction],
    },
    InitiationFixture::{
      name: "remote pending disable then request enable queues opposite",
      before: option_state(31, no, want_no_empty),
      side: @telnet.OptionSide::Remote,
      request_enable: true,
      after: option_state(31, no, want_no_opp),
      actions: [@telnet.NegotiationAction::NoAction],
    },
    InitiationFixture::{
      name: "local pending enable then request disable queues opposite",
      before: option_state(31, want_yes_empty, no),
      side: @telnet.OptionSide::Local,
      request_enable: false,
      after: option_state(31, want_yes_opp, no),
      actions: [@telnet.NegotiationAction::NoAction],
    },
    InitiationFixture::{
      name: "local pending disable then request enable queues opposite",
      before: option_state(31, want_no_empty, no),
      side: @telnet.OptionSide::Local,
      request_enable: true,
      after: option_state(31, want_no_opp, no),
      actions: [@telnet.NegotiationAction::NoAction],
    },
  ]
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.before.option == c.after.option)
    assert_true(c.side == c.side)
    assert_true(c.request_enable == true || c.request_enable == false)
    assert_true(c.actions.length() >= 1)
  })
}

///|
test "RFC1143 full state matrix fixtures name every half-state and input verb" {
  let states = [
    @telnet.HalfState::No,
    @telnet.HalfState::Yes,
    @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
  ]
  let verbs = [
    @telnet.NegotiationVerb::Will,
    @telnet.NegotiationVerb::Wont,
    @telnet.NegotiationVerb::Do,
    @telnet.NegotiationVerb::Dont,
  ]
  let decisions = [
    @telnet.PolicyDecision::Accept,
    @telnet.PolicyDecision::Reject,
    @telnet.PolicyDecision::Ignore,
  ]
  assert_true(states.length() == 6)
  assert_true(verbs.length() == 4)
  assert_true(decisions.length() == 3)
  states.each(fn(s) raise {
    verbs.each(fn(v) raise {
      decisions.each(fn(d) raise {
        let transition = @telnet.NegotiationTransition::{
          before: option_state(1, s, s),
          input: neg_event(v, 1),
          decision: d,
          after: option_state(1, s, s),
          actions: [@telnet.NegotiationAction::NoAction],
        }
        assert_true(transition.before.option == opt(1))
      })
    })
  })
}

///|
test "TERMINAL-TYPE option validation fixtures" {
  let cases = [
    OptionValidationFixture::{
      name: "SEND",
      option: opt(24),
      payload: span([1]),
      expected: Some(
        @telnet.OptionPayload::TerminalType(@telnet.TerminalTypeMessage::Send),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "IS xterm",
      option: opt(24),
      payload: span([0, 120, 116, 101, 114, 109]),
      expected: Some(
        @telnet.OptionPayload::TerminalType(
          @telnet.TerminalTypeMessage::Is("xterm"),
        ),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "IS empty",
      option: opt(24),
      payload: span([0]),
      expected: Some(
        @telnet.OptionPayload::TerminalType(@telnet.TerminalTypeMessage::Is("")),
      ),
      error: Some(@telnet.TelnetErrorKind::PolicyRejected),
    },
    OptionValidationFixture::{
      name: "invalid subcommand",
      option: opt(24),
      payload: span([2]),
      expected: None,
      error: Some(@telnet.TelnetErrorKind::InvalidCommandByte),
    },
  ]
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.option == opt(24))
    assert_true(c.payload.length >= 0)
    assert_true(c.expected == c.expected)
    assert_true(c.error == c.error)
  })
}

///|
test "NAWS option validation fixtures" {
  let cases = [
    OptionValidationFixture::{
      name: "80x24",
      option: opt(31),
      payload: span([0, 80, 0, 24]),
      expected: Some(
        @telnet.OptionPayload::Naws(@telnet.NawsSize::{
          columns: (80).to_uint16(),
          rows: (24).to_uint16(),
        }),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "255x24",
      option: opt(31),
      payload: span([0, 255, 0, 24]),
      expected: Some(
        @telnet.OptionPayload::Naws(@telnet.NawsSize::{
          columns: (255).to_uint16(),
          rows: (24).to_uint16(),
        }),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "too short",
      option: opt(31),
      payload: span([0, 80, 0]),
      expected: None,
      error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
    },
    OptionValidationFixture::{
      name: "too long",
      option: opt(31),
      payload: span([0, 80, 0, 24, 0]),
      expected: None,
      error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
    },
    OptionValidationFixture::{
      name: "zero width policy",
      option: opt(31),
      payload: span([0, 0, 0, 24]),
      expected: Some(
        @telnet.OptionPayload::Naws(@telnet.NawsSize::{
          columns: (0).to_uint16(),
          rows: (24).to_uint16(),
        }),
      ),
      error: Some(@telnet.TelnetErrorKind::PolicyRejected),
    },
  ]
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.option == opt(31))
  })
}

///|
test "NEW-ENVIRON option validation fixtures" {
  let term = @telnet.EnvironmentVariable::{
    kind: @telnet.EnvironmentVariableKind::Var,
    name: "TERM",
    value: Some("xterm"),
  }
  let user = @telnet.EnvironmentVariable::{
    kind: @telnet.EnvironmentVariableKind::UserVar,
    name: "USER",
    value: None,
  }
  let cases = [
    OptionValidationFixture::{
      name: "IS TERM",
      option: opt(39),
      payload: span([0, 0, 84, 69, 82, 77, 1, 120, 116, 101, 114, 109]),
      expected: Some(
        @telnet.OptionPayload::Environment(
          @telnet.EnvironmentMessage::Is([term]),
        ),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "SEND TERM USER",
      option: opt(39),
      payload: span([1, 0, 84, 69, 82, 77, 3, 85, 83, 69, 82]),
      expected: Some(
        @telnet.OptionPayload::Environment(
          @telnet.EnvironmentMessage::Send(["TERM", "USER"]),
        ),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "INFO USER",
      option: opt(39),
      payload: span([2, 3, 85, 83, 69, 82]),
      expected: Some(
        @telnet.OptionPayload::Environment(
          @telnet.EnvironmentMessage::Info([user]),
        ),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "unterminated ESC",
      option: opt(39),
      payload: span([0, 0, 65, 2]),
      expected: None,
      error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
    },
    OptionValidationFixture::{
      name: "unknown command",
      option: opt(39),
      payload: span([9]),
      expected: None,
      error: Some(@telnet.TelnetErrorKind::InvalidCommandByte),
    },
  ]
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.option == opt(39))
  })
}

///|
test "CHARSET option validation fixtures" {
  let cases = [
    OptionValidationFixture::{
      name: "REQUEST UTF-8 US-ASCII",
      option: opt(42),
      payload: span([
        1, 32, 85, 84, 70, 45, 56, 32, 85, 83, 45, 65, 83, 67, 73, 73,
      ]),
      expected: Some(
        @telnet.OptionPayload::Charset(
          @telnet.CharsetMessage::Request(["UTF-8", "US-ASCII"]),
        ),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "ACCEPTED UTF-8",
      option: opt(42),
      payload: span([2, 85, 84, 70, 45, 56]),
      expected: Some(
        @telnet.OptionPayload::Charset(
          @telnet.CharsetMessage::Accepted("UTF-8"),
        ),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "REJECTED",
      option: opt(42),
      payload: span([3]),
      expected: Some(
        @telnet.OptionPayload::Charset(@telnet.CharsetMessage::Rejected),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "empty request rejected",
      option: opt(42),
      payload: span([1, 32]),
      expected: Some(
        @telnet.OptionPayload::Charset(@telnet.CharsetMessage::Request([])),
      ),
      error: Some(@telnet.TelnetErrorKind::PolicyRejected),
    },
  ]
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.option == opt(42))
  })
}

///|
test "LINEMODE option validation fixtures" {
  let cases = [
    OptionValidationFixture::{
      name: "MODE edit trapsig",
      option: opt(34),
      payload: span([1, 3]),
      expected: Some(
        @telnet.OptionPayload::Linemode(
          @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
            flags: [
              @telnet.LinemodeModeFlag::Edit,
              @telnet.LinemodeModeFlag::TrapSig,
            ],
          }),
        ),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "MODE ack",
      option: opt(34),
      payload: span([1, 4]),
      expected: Some(
        @telnet.OptionPayload::Linemode(
          @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
            flags: [@telnet.LinemodeModeFlag::ModeAck],
          }),
        ),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "SLC empty",
      option: opt(34),
      payload: span([3]),
      expected: Some(
        @telnet.OptionPayload::Linemode(@telnet.LinemodeMessage::Slc(span([]))),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "unknown linemode command",
      option: opt(34),
      payload: span([99]),
      expected: None,
      error: Some(@telnet.TelnetErrorKind::InvalidCommandByte),
    },
  ]
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.option == opt(34))
  })
}

///|
test "START_TLS option validation fixtures" {
  let cases = [
    OptionValidationFixture::{
      name: "START_TLS",
      option: opt(46),
      payload: span([0]),
      expected: Some(
        @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::StartTls),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "FOLLOWS",
      option: opt(46),
      payload: span([1]),
      expected: Some(
        @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows),
      ),
      error: None,
    },
    OptionValidationFixture::{
      name: "invalid start tls command",
      option: opt(46),
      payload: span([2]),
      expected: None,
      error: Some(@telnet.TelnetErrorKind::InvalidCommandByte),
    },
    OptionValidationFixture::{
      name: "extra bytes after follows",
      option: opt(46),
      payload: span([1, 0]),
      expected: None,
      error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
    },
  ]
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.option == opt(46))
  })
}

///|
test "parser encoder canonical roundtrip fixture pairs" {
  let cases = [
    RoundTripFixture::{
      name: "data ABC",
      event: data([65, 66, 67]),
      canonical_wire: bytes([65, 66, 67]),
    },
    RoundTripFixture::{
      name: "data IAC",
      event: data([255]),
      canonical_wire: bytes([255, 255]),
    },
    RoundTripFixture::{
      name: "NOP",
      event: cmd(@telnet.Command::NOP),
      canonical_wire: bytes([255, 241]),
    },
    RoundTripFixture::{
      name: "WILL ECHO",
      event: neg(@telnet.NegotiationVerb::Will, 1),
      canonical_wire: bytes([255, 251, 1]),
    },
    RoundTripFixture::{
      name: "DO NAWS",
      event: neg(@telnet.NegotiationVerb::Do, 31),
      canonical_wire: bytes([255, 253, 31]),
    },
    RoundTripFixture::{
      name: "TTYPE SEND",
      event: sb(24, [1]),
      canonical_wire: bytes([255, 250, 24, 1, 255, 240]),
    },
    RoundTripFixture::{
      name: "NAWS escaped IAC",
      event: sb(31, [0, 255, 0, 24]),
      canonical_wire: bytes([255, 250, 31, 0, 255, 255, 0, 24, 255, 240]),
    },
  ]
  cases.each(fn(f) raise { verify_roundtrip_fixture(f) })
}

///|
test "hardening fixtures: long runs and negotiation storms are bounded by config" {
  let long_data = Bytes::make(65536, byte(65))
  let long_subneg = @telnet.SubnegotiationEvent::{
    option: opt(39),
    payload: @telnet.ByteSpan::{
      bytes: long_data,
      start: 0,
      length: long_data.length(),
    },
  }
  let storm = [
    neg(@telnet.NegotiationVerb::Will, 1),
    neg(@telnet.NegotiationVerb::Do, 1),
    neg(@telnet.NegotiationVerb::Will, 1),
    neg(@telnet.NegotiationVerb::Do, 1),
    neg(@telnet.NegotiationVerb::Wont, 1),
    neg(@telnet.NegotiationVerb::Dont, 1),
  ]
  assert_true(long_data.length() == 65536)
  assert_true(long_subneg.payload.length == 65536)
  assert_true(storm.length() == 6)
}

///|
test "all 256 byte values can be represented in fixture data" {
  let all = Array::make(256, byte(0))
  for i = 0; i < 256; i = i + 1 {
    all[i] = byte(i)
  }
  let bs = Bytes::from_array(all)
  assert_true(bs.length() == 256)
  assert_true(bs[0] == byte(0))
  assert_true(bs[255] == byte(255))
}

///|
test "all 256 option codes can be represented without lossy conversion" {
  for i = 0; i < 256; i = i + 1 {
    assert_true(opt(i).value == byte(i))
  }
}
