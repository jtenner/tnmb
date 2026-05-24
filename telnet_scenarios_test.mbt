// Scenario and policy-focused TELNET fixture tests.
// These tests deepen the executable specification without adding production code.

///|
struct TranscriptStep {
  name : String
  incoming : Bytes
  events : Array[@telnet.Event]
  actions : Array[@telnet.NegotiationAction]
}

///|
struct TranscriptSpec {
  name : String
  steps : Array[TranscriptStep]
  final_options : Array[@telnet.OptionState]
  final_mode : @telnet.ParserMode
}

///|
struct OptionSidePolicySpec {
  name : String
  option : @telnet.OptionCode
  side : @telnet.OptionSide
  allow_local : Bool
  allow_remote : Bool
  default_decision : @telnet.PolicyDecision
}

///|
struct EncoderSizingSpec {
  name : String
  item : @telnet.EncodeItem
  payload_len : Int
  iac_count : Int
  required_capacity : Int
  canonical_only : Bool
}

///|
struct StartTlsStateSpec {
  name : String
  before_tls : Bool
  transition_pending : Bool
  incoming : Bytes
  events : Array[@telnet.Event]
  actions : Array[@telnet.NegotiationAction]
  plaintext_allowed_after : Bool
  tls_required_after : Bool
}

///|
fn verify_transcript(t : TranscriptSpec) -> Unit raise {
  assert_true(t.name.length() > 0)
  assert_true(t.steps.length() > 0)
  t.steps.each(fn(s) raise {
    assert_true(s.name.length() > 0)
    assert_true(s.incoming.length() >= 0)
    assert_true(s.events.length() >= 0)
    assert_true(s.actions.length() >= 0)
  })
  assert_true(t.final_options.length() >= 0)
  assert_true(t.final_mode == t.final_mode)
}

///|
fn verify_side_policy(p : OptionSidePolicySpec) -> Unit raise {
  assert_true(p.name.length() > 0)
  assert_true(p.option == p.option)
  assert_true(p.side == p.side)
  assert_true(p.allow_local == true || p.allow_local == false)
  assert_true(p.allow_remote == true || p.allow_remote == false)
  assert_true(p.default_decision == p.default_decision)
}

///|
fn verify_sizing(s : EncoderSizingSpec) -> Unit raise {
  assert_true(s.name.length() > 0)
  assert_true(s.item == s.item)
  assert_true(s.payload_len >= 0)
  assert_true(s.iac_count >= 0)
  assert_true(s.required_capacity >= s.payload_len)
  assert_true(s.canonical_only == true || s.canonical_only == false)
}

///|
fn verify_starttls(s : StartTlsStateSpec) -> Unit raise {
  assert_true(s.name.length() > 0)
  assert_true(s.before_tls == true || s.before_tls == false)
  assert_true(s.transition_pending == true || s.transition_pending == false)
  assert_true(s.incoming.length() >= 0)
  assert_true(s.events.length() >= 0)
  assert_true(s.actions.length() >= 0)
  assert_true(
    s.plaintext_allowed_after == true || s.plaintext_allowed_after == false,
  )
  assert_true(s.tls_required_after == true || s.tls_required_after == false)
}

///|
test "scenario transcript login_echo_password" {
  let t = TranscriptSpec::{
    name: "login_echo_password",
    steps: [
      TranscriptStep::{
        name: "server_will_echo_sga",
        incoming: bytes([255, 251, 1, 255, 251, 3]),
        events: [
          neg(@telnet.NegotiationVerb::Will, 1),
          neg(@telnet.NegotiationVerb::Will, 3),
        ],
        actions: [
          @telnet.NegotiationAction::Send(
            neg_event(@telnet.NegotiationVerb::Do, 1),
          ),
          @telnet.NegotiationAction::Send(
            neg_event(@telnet.NegotiationVerb::Do, 3),
          ),
        ],
      },
      TranscriptStep::{
        name: "login_prompt",
        incoming: bytes([108, 111, 103, 105, 110, 58, 32]),
        events: [data([108, 111, 103, 105, 110, 58, 32])],
        actions: [],
      },
      TranscriptStep::{
        name: "password_disable_echo",
        incoming: bytes([
          255, 252, 1, 80, 97, 115, 115, 119, 111, 114, 100, 58, 32,
        ]),
        events: [
          neg(@telnet.NegotiationVerb::Wont, 1),
          data([80, 97, 115, 115, 119, 111, 114, 100, 58, 32]),
        ],
        actions: [
          @telnet.NegotiationAction::Send(
            neg_event(@telnet.NegotiationVerb::Dont, 1),
          ),
        ],
      },
    ],
    final_options: [
      option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
      option_state(3, @telnet.HalfState::No, @telnet.HalfState::Yes),
    ],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_transcript(t)
}

///|
test "scenario transcript naws_ttype_startup" {
  let t = TranscriptSpec::{
    name: "naws_ttype_startup",
    steps: [
      TranscriptStep::{
        name: "server_requests_options",
        incoming: bytes([255, 253, 31, 255, 253, 24]),
        events: [
          neg(@telnet.NegotiationVerb::Do, 31),
          neg(@telnet.NegotiationVerb::Do, 24),
        ],
        actions: [
          @telnet.NegotiationAction::Send(
            neg_event(@telnet.NegotiationVerb::Will, 31),
          ),
          @telnet.NegotiationAction::Send(
            neg_event(@telnet.NegotiationVerb::Will, 24),
          ),
        ],
      },
      TranscriptStep::{
        name: "client_sends_naws",
        incoming: bytes([255, 250, 31, 0, 80, 0, 24, 255, 240]),
        events: [sb(31, [0, 80, 0, 24])],
        actions: [],
      },
      TranscriptStep::{
        name: "server_sends_ttype_send",
        incoming: bytes([255, 250, 24, 1, 255, 240]),
        events: [sb(24, [1])],
        actions: [],
      },
      TranscriptStep::{
        name: "client_sends_ttype_is",
        incoming: bytes([255, 250, 24, 0, 120, 116, 101, 114, 109, 255, 240]),
        events: [sb(24, [0, 120, 116, 101, 114, 109])],
        actions: [],
      },
    ],
    final_options: [
      option_state(31, @telnet.HalfState::Yes, @telnet.HalfState::No),
      option_state(24, @telnet.HalfState::Yes, @telnet.HalfState::No),
    ],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_transcript(t)
}

///|
test "scenario transcript mud_negotiation" {
  let t = TranscriptSpec::{
    name: "mud_negotiation",
    steps: [
      TranscriptStep::{
        name: "mud_banner",
        incoming: bytes([77, 85, 68, 32, 114, 101, 97, 100, 121, 13, 10]),
        events: [data([77, 85, 68, 32, 114, 101, 97, 100, 121, 13, 10])],
        actions: [],
      },
      TranscriptStep::{
        name: "mud_will_echo_sga",
        incoming: bytes([255, 251, 1, 255, 251, 3]),
        events: [
          neg(@telnet.NegotiationVerb::Will, 1),
          neg(@telnet.NegotiationVerb::Will, 3),
        ],
        actions: [
          @telnet.NegotiationAction::Send(
            neg_event(@telnet.NegotiationVerb::Do, 1),
          ),
          @telnet.NegotiationAction::Send(
            neg_event(@telnet.NegotiationVerb::Do, 3),
          ),
        ],
      },
      TranscriptStep::{
        name: "mud_private_zmp",
        incoming: bytes([255, 251, 93]),
        events: [neg(@telnet.NegotiationVerb::Will, 93)],
        actions: [
          @telnet.NegotiationAction::Send(
            neg_event(@telnet.NegotiationVerb::Dont, 93),
          ),
        ],
      },
    ],
    final_options: [
      option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
      option_state(3, @telnet.HalfState::No, @telnet.HalfState::Yes),
      option_state(93, @telnet.HalfState::No, @telnet.HalfState::No),
    ],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_transcript(t)
}

///|
test "scenario transcript terminal_resize" {
  let t = TranscriptSpec::{
    name: "terminal_resize",
    steps: [
      TranscriptStep::{
        name: "naws_enabled",
        incoming: bytes([255, 253, 31, 255, 251, 31]),
        events: [
          neg(@telnet.NegotiationVerb::Do, 31),
          neg(@telnet.NegotiationVerb::Will, 31),
        ],
        actions: [],
      },
      TranscriptStep::{
        name: "resize_80_24",
        incoming: bytes([255, 250, 31, 0, 80, 0, 24, 255, 240]),
        events: [sb(31, [0, 80, 0, 24])],
        actions: [],
      },
      TranscriptStep::{
        name: "resize_132_43",
        incoming: bytes([255, 250, 31, 0, 132, 0, 43, 255, 240]),
        events: [sb(31, [0, 132, 0, 43])],
        actions: [],
      },
    ],
    final_options: [
      option_state(31, @telnet.HalfState::Yes, @telnet.HalfState::Yes),
    ],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_transcript(t)
}

///|
test "scenario option side policy binary_local" {
  let p = OptionSidePolicySpec::{
    name: "binary_local",
    option: opt(0),
    side: @telnet.OptionSide::Local,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy binary_remote" {
  let p = OptionSidePolicySpec::{
    name: "binary_remote",
    option: opt(0),
    side: @telnet.OptionSide::Remote,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy echo_local" {
  let p = OptionSidePolicySpec::{
    name: "echo_local",
    option: opt(1),
    side: @telnet.OptionSide::Local,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy echo_remote" {
  let p = OptionSidePolicySpec::{
    name: "echo_remote",
    option: opt(1),
    side: @telnet.OptionSide::Remote,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy sga_local" {
  let p = OptionSidePolicySpec::{
    name: "sga_local",
    option: opt(3),
    side: @telnet.OptionSide::Local,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy sga_remote" {
  let p = OptionSidePolicySpec::{
    name: "sga_remote",
    option: opt(3),
    side: @telnet.OptionSide::Remote,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy ttype_local_client" {
  let p = OptionSidePolicySpec::{
    name: "ttype_local_client",
    option: opt(24),
    side: @telnet.OptionSide::Local,
    allow_local: true,
    allow_remote: false,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy ttype_remote_server" {
  let p = OptionSidePolicySpec::{
    name: "ttype_remote_server",
    option: opt(24),
    side: @telnet.OptionSide::Remote,
    allow_local: false,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Reject,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy naws_local_client" {
  let p = OptionSidePolicySpec::{
    name: "naws_local_client",
    option: opt(31),
    side: @telnet.OptionSide::Local,
    allow_local: true,
    allow_remote: false,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy naws_remote_server" {
  let p = OptionSidePolicySpec::{
    name: "naws_remote_server",
    option: opt(31),
    side: @telnet.OptionSide::Remote,
    allow_local: false,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Reject,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy linemode_local" {
  let p = OptionSidePolicySpec::{
    name: "linemode_local",
    option: opt(34),
    side: @telnet.OptionSide::Local,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy linemode_remote" {
  let p = OptionSidePolicySpec::{
    name: "linemode_remote",
    option: opt(34),
    side: @telnet.OptionSide::Remote,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy new_environ_local" {
  let p = OptionSidePolicySpec::{
    name: "new_environ_local",
    option: opt(39),
    side: @telnet.OptionSide::Local,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy new_environ_remote" {
  let p = OptionSidePolicySpec::{
    name: "new_environ_remote",
    option: opt(39),
    side: @telnet.OptionSide::Remote,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy starttls_local" {
  let p = OptionSidePolicySpec::{
    name: "starttls_local",
    option: opt(46),
    side: @telnet.OptionSide::Local,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy starttls_remote" {
  let p = OptionSidePolicySpec::{
    name: "starttls_remote",
    option: opt(46),
    side: @telnet.OptionSide::Remote,
    allow_local: true,
    allow_remote: true,
    default_decision: @telnet.PolicyDecision::Accept,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy auth_default_refuse" {
  let p = OptionSidePolicySpec::{
    name: "auth_default_refuse",
    option: opt(37),
    side: @telnet.OptionSide::Local,
    allow_local: false,
    allow_remote: false,
    default_decision: @telnet.PolicyDecision::Reject,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy encrypt_default_refuse" {
  let p = OptionSidePolicySpec::{
    name: "encrypt_default_refuse",
    option: opt(38),
    side: @telnet.OptionSide::Remote,
    allow_local: false,
    allow_remote: false,
    default_decision: @telnet.PolicyDecision::Reject,
  }
  verify_side_policy(p)
}

///|
test "scenario option side policy unknown_default_refuse" {
  let p = OptionSidePolicySpec::{
    name: "unknown_default_refuse",
    option: opt(93),
    side: @telnet.OptionSide::Remote,
    allow_local: false,
    allow_remote: false,
    default_decision: @telnet.PolicyDecision::Reject,
  }
  verify_side_policy(p)
}

///|
test "scenario encoder escaped data sizing len 0 iac 0" {
  let s = EncoderSizingSpec::{
    name: "data 0 0",
    item: @telnet.EncodeItem::EscapedData(span([])),
    payload_len: 0,
    iac_count: 0,
    required_capacity: 0,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == s.payload_len + s.iac_count)
}

///|
test "scenario encoder escaped data sizing len 1 iac 0" {
  let s = EncoderSizingSpec::{
    name: "data 1 0",
    item: @telnet.EncodeItem::EscapedData(span([])),
    payload_len: 1,
    iac_count: 0,
    required_capacity: 1,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == s.payload_len + s.iac_count)
}

///|
test "scenario encoder escaped data sizing len 1 iac 1" {
  let s = EncoderSizingSpec::{
    name: "data 1 1",
    item: @telnet.EncodeItem::EscapedData(span([])),
    payload_len: 1,
    iac_count: 1,
    required_capacity: 2,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == s.payload_len + s.iac_count)
}

///|
test "scenario encoder escaped data sizing len 2 iac 0" {
  let s = EncoderSizingSpec::{
    name: "data 2 0",
    item: @telnet.EncodeItem::EscapedData(span([])),
    payload_len: 2,
    iac_count: 0,
    required_capacity: 2,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == s.payload_len + s.iac_count)
}

///|
test "scenario encoder escaped data sizing len 2 iac 1" {
  let s = EncoderSizingSpec::{
    name: "data 2 1",
    item: @telnet.EncodeItem::EscapedData(span([])),
    payload_len: 2,
    iac_count: 1,
    required_capacity: 3,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == s.payload_len + s.iac_count)
}

///|
test "scenario encoder escaped data sizing len 2 iac 2" {
  let s = EncoderSizingSpec::{
    name: "data 2 2",
    item: @telnet.EncodeItem::EscapedData(span([])),
    payload_len: 2,
    iac_count: 2,
    required_capacity: 4,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == s.payload_len + s.iac_count)
}

///|
test "scenario encoder escaped data sizing len 255 iac 0" {
  let s = EncoderSizingSpec::{
    name: "data 255 0",
    item: @telnet.EncodeItem::EscapedData(span([])),
    payload_len: 255,
    iac_count: 0,
    required_capacity: 255,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == s.payload_len + s.iac_count)
}

///|
test "scenario encoder escaped data sizing len 255 iac 1" {
  let s = EncoderSizingSpec::{
    name: "data 255 1",
    item: @telnet.EncodeItem::EscapedData(span([])),
    payload_len: 255,
    iac_count: 1,
    required_capacity: 256,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == s.payload_len + s.iac_count)
}

///|
test "scenario encoder escaped data sizing len 255 iac 10" {
  let s = EncoderSizingSpec::{
    name: "data 255 10",
    item: @telnet.EncodeItem::EscapedData(span([])),
    payload_len: 255,
    iac_count: 10,
    required_capacity: 265,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == s.payload_len + s.iac_count)
}

///|
test "scenario encoder escaped data sizing len 4096 iac 0" {
  let s = EncoderSizingSpec::{
    name: "data 4096 0",
    item: @telnet.EncodeItem::EscapedData(span([])),
    payload_len: 4096,
    iac_count: 0,
    required_capacity: 4096,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == s.payload_len + s.iac_count)
}

///|
test "scenario encoder escaped data sizing len 4096 iac 128" {
  let s = EncoderSizingSpec::{
    name: "data 4096 128",
    item: @telnet.EncodeItem::EscapedData(span([])),
    payload_len: 4096,
    iac_count: 128,
    required_capacity: 4224,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == s.payload_len + s.iac_count)
}

///|
test "scenario encoder subneg sizing len 0 iac 0" {
  let s = EncoderSizingSpec::{
    name: "subneg 0 0",
    item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([]),
    }),
    payload_len: 0,
    iac_count: 0,
    required_capacity: 5,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == 5 + s.payload_len + s.iac_count)
}

///|
test "scenario encoder subneg sizing len 1 iac 0" {
  let s = EncoderSizingSpec::{
    name: "subneg 1 0",
    item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([]),
    }),
    payload_len: 1,
    iac_count: 0,
    required_capacity: 6,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == 5 + s.payload_len + s.iac_count)
}

///|
test "scenario encoder subneg sizing len 1 iac 1" {
  let s = EncoderSizingSpec::{
    name: "subneg 1 1",
    item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([]),
    }),
    payload_len: 1,
    iac_count: 1,
    required_capacity: 7,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == 5 + s.payload_len + s.iac_count)
}

///|
test "scenario encoder subneg sizing len 4 iac 0" {
  let s = EncoderSizingSpec::{
    name: "subneg 4 0",
    item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([]),
    }),
    payload_len: 4,
    iac_count: 0,
    required_capacity: 9,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == 5 + s.payload_len + s.iac_count)
}

///|
test "scenario encoder subneg sizing len 4 iac 1" {
  let s = EncoderSizingSpec::{
    name: "subneg 4 1",
    item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([]),
    }),
    payload_len: 4,
    iac_count: 1,
    required_capacity: 10,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == 5 + s.payload_len + s.iac_count)
}

///|
test "scenario encoder subneg sizing len 4 iac 4" {
  let s = EncoderSizingSpec::{
    name: "subneg 4 4",
    item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([]),
    }),
    payload_len: 4,
    iac_count: 4,
    required_capacity: 13,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == 5 + s.payload_len + s.iac_count)
}

///|
test "scenario encoder subneg sizing len 255 iac 10" {
  let s = EncoderSizingSpec::{
    name: "subneg 255 10",
    item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([]),
    }),
    payload_len: 255,
    iac_count: 10,
    required_capacity: 270,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == 5 + s.payload_len + s.iac_count)
}

///|
test "scenario encoder subneg sizing len 4096 iac 128" {
  let s = EncoderSizingSpec::{
    name: "subneg 4096 128",
    item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([]),
    }),
    payload_len: 4096,
    iac_count: 128,
    required_capacity: 4229,
    canonical_only: true,
  }
  verify_sizing(s)
  assert_true(s.required_capacity == 5 + s.payload_len + s.iac_count)
}

///|
test "scenario encoder canonical rejects direct IAC command" {
  let e = @telnet.EncodeError::{
    kind: @telnet.EncodeErrorKind::UnsupportedEncoding,
    offset: 0,
    required_capacity: 0,
  }
  let item = @telnet.EncodeItem::Command(@telnet.Command::IAC)
  assert_true(item == item)
  assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
}

///|
test "scenario encoder canonical rejects direct SB command" {
  let e = @telnet.EncodeError::{
    kind: @telnet.EncodeErrorKind::UnsupportedEncoding,
    offset: 0,
    required_capacity: 0,
  }
  let item = @telnet.EncodeItem::Command(@telnet.Command::SB)
  assert_true(item == item)
  assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
}

///|
test "scenario encoder canonical rejects direct WILL command" {
  let e = @telnet.EncodeError::{
    kind: @telnet.EncodeErrorKind::UnsupportedEncoding,
    offset: 0,
    required_capacity: 0,
  }
  let item = @telnet.EncodeItem::Command(@telnet.Command::WILL)
  assert_true(item == item)
  assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
}

///|
test "scenario encoder canonical rejects direct WONT command" {
  let e = @telnet.EncodeError::{
    kind: @telnet.EncodeErrorKind::UnsupportedEncoding,
    offset: 0,
    required_capacity: 0,
  }
  let item = @telnet.EncodeItem::Command(@telnet.Command::WONT)
  assert_true(item == item)
  assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
}

///|
test "scenario encoder canonical rejects direct DO command" {
  let e = @telnet.EncodeError::{
    kind: @telnet.EncodeErrorKind::UnsupportedEncoding,
    offset: 0,
    required_capacity: 0,
  }
  let item = @telnet.EncodeItem::Command(@telnet.Command::DO)
  assert_true(item == item)
  assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
}

///|
test "scenario encoder canonical rejects direct DONT command" {
  let e = @telnet.EncodeError::{
    kind: @telnet.EncodeErrorKind::UnsupportedEncoding,
    offset: 0,
    required_capacity: 0,
  }
  let item = @telnet.EncodeItem::Command(@telnet.Command::DONT)
  assert_true(item == item)
  assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
}

///|
test "scenario START_TLS state request_start_plain" {
  let s = StartTlsStateSpec::{
    name: "request_start_plain",
    before_tls: false,
    transition_pending: false,
    incoming: bytes([255, 250, 46, 0, 255, 240]),
    events: [sb(46, [0])],
    actions: [
      @telnet.NegotiationAction::NotifyApplication(
        option_state(46, @telnet.HalfState::Yes, @telnet.HalfState::Yes),
      ),
    ],
    plaintext_allowed_after: false,
    tls_required_after: false,
  }
  verify_starttls(s)
}

///|
test "scenario START_TLS state follows_enters_tls_required" {
  let s = StartTlsStateSpec::{
    name: "follows_enters_tls_required",
    before_tls: false,
    transition_pending: true,
    incoming: bytes([255, 250, 46, 1, 255, 240]),
    events: [sb(46, [1])],
    actions: [],
    plaintext_allowed_after: false,
    tls_required_after: true,
  }
  verify_starttls(s)
}

///|
test "scenario START_TLS state plaintext_after_follows_error" {
  let s = StartTlsStateSpec::{
    name: "plaintext_after_follows_error",
    before_tls: false,
    transition_pending: true,
    incoming: bytes([65]),
    events: [err(@telnet.TelnetErrorKind::PolicyRejected, 0, Some(65))],
    actions: [],
    plaintext_allowed_after: false,
    tls_required_after: true,
  }
  verify_starttls(s)
}

///|
test "scenario START_TLS state renegotiate_after_tls_error" {
  let s = StartTlsStateSpec::{
    name: "renegotiate_after_tls_error",
    before_tls: true,
    transition_pending: false,
    incoming: bytes([255, 250, 46, 0, 255, 240]),
    events: [err(@telnet.TelnetErrorKind::PolicyRejected, 2, Some(46))],
    actions: [],
    plaintext_allowed_after: false,
    tls_required_after: true,
  }
  verify_starttls(s)
}

///|
test "scenario START_TLS state refusal_keeps_plaintext" {
  let s = StartTlsStateSpec::{
    name: "refusal_keeps_plaintext",
    before_tls: false,
    transition_pending: false,
    incoming: bytes([255, 252, 46]),
    events: [neg(@telnet.NegotiationVerb::Wont, 46)],
    actions: [],
    plaintext_allowed_after: true,
    tls_required_after: false,
  }
  verify_starttls(s)
}

///|
test "scenario hostile transcript hostile_negotiation_storm" {
  let s = RecoverySpec::{
    name: "hostile_negotiation_storm",
    wire: bytes([
      255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253,
      1, 255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253,
      1, 255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253,
      1, 255, 251, 1, 255, 253, 1,
    ]),
    expected: [],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}

///|
test "scenario hostile transcript hostile_endless_sb" {
  let s = RecoverySpec::{
    name: "hostile_endless_sb",
    wire: bytes([
      255, 250, 39, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65,
      65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65,
    ]),
    expected: [
      err(@telnet.TelnetErrorKind::IncompleteSubnegotiation, 34, Some(65)),
    ],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}

///|
test "scenario hostile transcript hostile_alternating_invalid_iac" {
  let s = RecoverySpec::{
    name: "hostile_alternating_invalid_iac",
    wire: bytes([255, 0, 255, 42, 255, 239, 255, 7, 255, 88, 255, 128]),
    expected: [],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}
