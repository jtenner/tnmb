// Blackbox tests run against the package's public API. Use `@telnet` to import.
//
// These tests are intentionally fixture-first. They compile the public data
// model into a large executable specification corpus before production parser,
// encoder, or negotiator functions exist. Implementation work should replace
// the fixture self-checks with calls into the real parser/encoder while keeping
// the expected events and wire bytes below unchanged.

///|
fn byte(n : Int) -> Byte {
  n.to_byte()
}

///|
fn bytes(ns : Array[Int]) -> Bytes {
  Bytes::from_array(ns.map(fn(n) { byte(n) }))
}

///|
fn opt(n : Int) -> @telnet.OptionCode {
  @telnet.OptionCode::{ value: byte(n) }
}

///|
fn span(ns : Array[Int]) -> @telnet.ByteSpan {
  let bs = bytes(ns)
  @telnet.ByteSpan::{ bytes: bs, start: 0, length: bs.length() }
}

///|
fn slice(ns : Array[Int], start : Int, length : Int) -> @telnet.ByteSpan {
  @telnet.ByteSpan::{ bytes: bytes(ns), start, length }
}

///|
fn data(ns : Array[Int]) -> @telnet.Event {
  @telnet.Event::Data(@telnet.DataEvent::{ span: span(ns) })
}

///|
fn cmd(command : @telnet.Command) -> @telnet.Event {
  @telnet.Event::Command(@telnet.CommandEvent::{ command, })
}

///|
fn neg(verb : @telnet.NegotiationVerb, option : Int) -> @telnet.Event {
  @telnet.Event::Negotiation(@telnet.NegotiationEvent::{
    verb,
    option: opt(option),
  })
}

///|
fn sb(option : Int, payload : Array[Int]) -> @telnet.Event {
  @telnet.Event::Subnegotiation(@telnet.SubnegotiationEvent::{
    option: opt(option),
    payload: span(payload),
  })
}

///|
fn err(
  kind : @telnet.TelnetErrorKind,
  offset : Int,
  byte_value : Int?,
) -> @telnet.Event {
  let b = match byte_value {
    Some(n) => Some(byte(n))
    None => None
  }
  @telnet.Event::Error(@telnet.TelnetError::{
    kind,
    offset,
    byte: b,
    option: None,
  })
}

///|
fn neg_event(
  verb : @telnet.NegotiationVerb,
  option : Int,
) -> @telnet.NegotiationEvent {
  @telnet.NegotiationEvent::{ verb, option: opt(option) }
}

///|
fn option_state(
  option : Int,
  local_state : @telnet.HalfState,
  remote_state : @telnet.HalfState,
) -> @telnet.OptionState {
  @telnet.OptionState::{ option: opt(option), local_state, remote_state }
}

///|
struct CommandByteCase {
  byte : Int
  command : @telnet.Command
}

///|
struct OptionCase {
  byte : Int
  known : @telnet.KnownOption
}

///|
struct ParserFixture {
  name : String
  wire : Bytes
  expected : Array[@telnet.Event]
  final_mode : @telnet.ParserMode
}

///|
struct EncoderFixture {
  name : String
  item : @telnet.EncodeItem
  expected_wire : Bytes
}

///|
struct ChunkFixture {
  name : String
  wire : Bytes
  split_points : Array[Int]
  expected_final_mode : @telnet.ParserMode
}

///|
struct NegotiationFixture {
  name : String
  before : @telnet.OptionState
  input : @telnet.NegotiationEvent
  decision : @telnet.PolicyDecision
  after : @telnet.OptionState
  actions : Array[@telnet.NegotiationAction]
}

///|
test "RFC 854 command byte table is complete" {
  let cases = [
    CommandByteCase::{ byte: 240, command: @telnet.Command::SE },
    CommandByteCase::{ byte: 241, command: @telnet.Command::NOP },
    CommandByteCase::{ byte: 242, command: @telnet.Command::DM },
    CommandByteCase::{ byte: 243, command: @telnet.Command::BRK },
    CommandByteCase::{ byte: 244, command: @telnet.Command::IP },
    CommandByteCase::{ byte: 245, command: @telnet.Command::AO },
    CommandByteCase::{ byte: 246, command: @telnet.Command::AYT },
    CommandByteCase::{ byte: 247, command: @telnet.Command::EC },
    CommandByteCase::{ byte: 248, command: @telnet.Command::EL },
    CommandByteCase::{ byte: 249, command: @telnet.Command::GA },
    CommandByteCase::{ byte: 250, command: @telnet.Command::SB },
    CommandByteCase::{ byte: 251, command: @telnet.Command::WILL },
    CommandByteCase::{ byte: 252, command: @telnet.Command::WONT },
    CommandByteCase::{ byte: 253, command: @telnet.Command::DO },
    CommandByteCase::{ byte: 254, command: @telnet.Command::DONT },
    CommandByteCase::{ byte: 255, command: @telnet.Command::IAC },
  ]
  assert_true(cases.length() == 16)
  cases.each(fn(c) raise {
    assert_true(c.byte >= 240 && c.byte <= 255)
    assert_true(c.command == c.command)
  })
}

///|
test "well-known option table covers common RFC and IANA assignments" {
  let cases = [
    OptionCase::{ byte: 0, known: @telnet.KnownOption::Binary },
    OptionCase::{ byte: 1, known: @telnet.KnownOption::Echo },
    OptionCase::{ byte: 2, known: @telnet.KnownOption::Reconnection },
    OptionCase::{ byte: 3, known: @telnet.KnownOption::SuppressGoAhead },
    OptionCase::{ byte: 5, known: @telnet.KnownOption::Status },
    OptionCase::{ byte: 6, known: @telnet.KnownOption::TimingMark },
    OptionCase::{ byte: 18, known: @telnet.KnownOption::Logout },
    OptionCase::{ byte: 24, known: @telnet.KnownOption::TerminalType },
    OptionCase::{ byte: 25, known: @telnet.KnownOption::EndOfRecord },
    OptionCase::{ byte: 31, known: @telnet.KnownOption::Naws },
    OptionCase::{ byte: 32, known: @telnet.KnownOption::TerminalSpeed },
    OptionCase::{ byte: 33, known: @telnet.KnownOption::RemoteFlowControl },
    OptionCase::{ byte: 34, known: @telnet.KnownOption::Linemode },
    OptionCase::{ byte: 35, known: @telnet.KnownOption::XDisplayLocation },
    OptionCase::{ byte: 36, known: @telnet.KnownOption::Environment },
    OptionCase::{ byte: 37, known: @telnet.KnownOption::Authentication },
    OptionCase::{ byte: 38, known: @telnet.KnownOption::Encryption },
    OptionCase::{ byte: 39, known: @telnet.KnownOption::NewEnvironment },
    OptionCase::{ byte: 40, known: @telnet.KnownOption::Tn3270e },
    OptionCase::{ byte: 42, known: @telnet.KnownOption::Charset },
    OptionCase::{ byte: 44, known: @telnet.KnownOption::ComPortControl },
    OptionCase::{
      byte: 45,
      known: @telnet.KnownOption::TelnetSuppressLocalEcho,
    },
    OptionCase::{ byte: 46, known: @telnet.KnownOption::TelnetStartTls },
    OptionCase::{ byte: 255, known: @telnet.KnownOption::ExtendedOptionsList },
  ]
  assert_true(cases.length() == 24)
  cases.each(fn(c) raise {
    assert_true(opt(c.byte).value == byte(c.byte))
    assert_true(c.known == c.known)
  })
}

///|
test "parser fixture corpus covers ordinary data and all simple IAC commands" {
  let cases = [
    ParserFixture::{
      name: "empty input",
      wire: bytes([]),
      expected: [],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "single line",
      wire: bytes([84, 104, 105, 115]),
      expected: [data([84, 104, 105, 115])],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "embedded nul preserved in binary-safe core",
      wire: bytes([65, 0, 66]),
      expected: [data([65, 0, 66])],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "escaped IAC data",
      wire: bytes([255, 255]),
      expected: [data([255])],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "data then escaped IAC then data",
      wire: bytes([65, 255, 255, 66]),
      expected: [data([65]), data([255]), data([66])],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "NOP",
      wire: bytes([255, 241]),
      expected: [cmd(@telnet.Command::NOP)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "DM",
      wire: bytes([255, 242]),
      expected: [cmd(@telnet.Command::DM)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "BRK",
      wire: bytes([255, 243]),
      expected: [cmd(@telnet.Command::BRK)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "IP",
      wire: bytes([255, 244]),
      expected: [cmd(@telnet.Command::IP)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "AO",
      wire: bytes([255, 245]),
      expected: [cmd(@telnet.Command::AO)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "AYT",
      wire: bytes([255, 246]),
      expected: [cmd(@telnet.Command::AYT)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "EC",
      wire: bytes([255, 247]),
      expected: [cmd(@telnet.Command::EC)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "EL",
      wire: bytes([255, 248]),
      expected: [cmd(@telnet.Command::EL)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "GA",
      wire: bytes([255, 249]),
      expected: [cmd(@telnet.Command::GA)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "SE outside subnegotiation",
      wire: bytes([255, 240]),
      expected: [cmd(@telnet.Command::SE)],
      final_mode: @telnet.ParserMode::Normal,
    },
  ]
  assert_true(cases.length() == 15)
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.final_mode == @telnet.ParserMode::Normal)
    assert_true(c.wire.length() >= 0)
  })
}

///|
test "parser fixture corpus covers negotiation triplets" {
  let cases = [
    ParserFixture::{
      name: "WILL ECHO",
      wire: bytes([255, 251, 1]),
      expected: [neg(@telnet.NegotiationVerb::Will, 1)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "WONT ECHO",
      wire: bytes([255, 252, 1]),
      expected: [neg(@telnet.NegotiationVerb::Wont, 1)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "DO SUPPRESS-GO-AHEAD",
      wire: bytes([255, 253, 3]),
      expected: [neg(@telnet.NegotiationVerb::Do, 3)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "DONT SUPPRESS-GO-AHEAD",
      wire: bytes([255, 254, 3]),
      expected: [neg(@telnet.NegotiationVerb::Dont, 3)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "WILL TERMINAL-TYPE",
      wire: bytes([255, 251, 24]),
      expected: [neg(@telnet.NegotiationVerb::Will, 24)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "DO NAWS",
      wire: bytes([255, 253, 31]),
      expected: [neg(@telnet.NegotiationVerb::Do, 31)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "WILL NAWS",
      wire: bytes([255, 251, 31]),
      expected: [neg(@telnet.NegotiationVerb::Will, 31)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "DO LINEMODE",
      wire: bytes([255, 253, 34]),
      expected: [neg(@telnet.NegotiationVerb::Do, 34)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "WONT unknown private option",
      wire: bytes([255, 252, 93]),
      expected: [neg(@telnet.NegotiationVerb::Wont, 93)],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "DO extended option list",
      wire: bytes([255, 253, 255]),
      expected: [neg(@telnet.NegotiationVerb::Do, 255)],
      final_mode: @telnet.ParserMode::Normal,
    },
  ]
  assert_true(cases.length() == 10)
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.expected.length() == 1)
  })
}

///|
test "parser fixture corpus covers subnegotiation framing and escaping" {
  let cases = [
    ParserFixture::{
      name: "TTYPE SEND",
      wire: bytes([255, 250, 24, 1, 255, 240]),
      expected: [sb(24, [1])],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "TTYPE IS xterm",
      wire: bytes([255, 250, 24, 0, 120, 116, 101, 114, 109, 255, 240]),
      expected: [sb(24, [0, 120, 116, 101, 114, 109])],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "NAWS 80x24",
      wire: bytes([255, 250, 31, 0, 80, 0, 24, 255, 240]),
      expected: [sb(31, [0, 80, 0, 24])],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "NAWS 255x24 escapes width low byte",
      wire: bytes([255, 250, 31, 0, 255, 255, 0, 24, 255, 240]),
      expected: [sb(31, [0, 255, 0, 24])],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "NEW-ENVIRON SEND VAR FOO USERVAR BAR",
      wire: bytes([255, 250, 39, 1, 0, 70, 79, 79, 3, 66, 65, 82, 255, 240]),
      expected: [sb(39, [1, 0, 70, 79, 79, 3, 66, 65, 82])],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "ENVIRON legacy SEND all",
      wire: bytes([255, 250, 36, 1, 255, 240]),
      expected: [sb(36, [1])],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "CHARSET REQUEST UTF-8",
      wire: bytes([255, 250, 42, 1, 32, 85, 84, 70, 45, 56, 255, 240]),
      expected: [sb(42, [1, 32, 85, 84, 70, 45, 56])],
      final_mode: @telnet.ParserMode::Normal,
    },
    ParserFixture::{
      name: "START_TLS FOLLOWS",
      wire: bytes([255, 250, 46, 1, 255, 240]),
      expected: [sb(46, [1])],
      final_mode: @telnet.ParserMode::Normal,
    },
  ]
  assert_true(cases.length() == 8)
  cases.each(fn(c) raise {
    assert_true(c.final_mode == @telnet.ParserMode::Normal)
  })
}

///|
test "parser fixture corpus covers incomplete and malformed endings" {
  let cases = [
    ParserFixture::{
      name: "dangling IAC",
      wire: bytes([255]),
      expected: [err(@telnet.TelnetErrorKind::IncompleteIac, 0, Some(255))],
      final_mode: @telnet.ParserMode::AfterIac,
    },
    ParserFixture::{
      name: "dangling WILL",
      wire: bytes([255, 251]),
      expected: [
        err(@telnet.TelnetErrorKind::IncompleteNegotiation, 1, Some(251)),
      ],
      final_mode: @telnet.ParserMode::AfterNegotiationVerb(
        @telnet.NegotiationVerb::Will,
      ),
    },
    ParserFixture::{
      name: "dangling DO",
      wire: bytes([255, 253]),
      expected: [
        err(@telnet.TelnetErrorKind::IncompleteNegotiation, 1, Some(253)),
      ],
      final_mode: @telnet.ParserMode::AfterNegotiationVerb(
        @telnet.NegotiationVerb::Do,
      ),
    },
    ParserFixture::{
      name: "dangling SB",
      wire: bytes([255, 250]),
      expected: [
        err(@telnet.TelnetErrorKind::IncompleteSubnegotiation, 1, Some(250)),
      ],
      final_mode: @telnet.ParserMode::AfterSubnegotiationStart,
    },
    ParserFixture::{
      name: "unterminated TTYPE",
      wire: bytes([255, 250, 24, 1]),
      expected: [
        err(@telnet.TelnetErrorKind::IncompleteSubnegotiation, 3, Some(1)),
      ],
      final_mode: @telnet.ParserMode::InSubnegotiation(opt(24)),
    },
    ParserFixture::{
      name: "subnegotiation IAC before final byte",
      wire: bytes([255, 250, 24, 1, 255]),
      expected: [
        err(@telnet.TelnetErrorKind::IncompleteSubnegotiation, 4, Some(255)),
      ],
      final_mode: @telnet.ParserMode::InSubnegotiationAfterIac(opt(24)),
    },
  ]
  assert_true(cases.length() == 6)
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.expected.length() == 1)
  })
}

///|
test "chunk-boundary fixture corpus covers every state split" {
  let cases = [
    ChunkFixture::{
      name: "split before IAC",
      wire: bytes([65, 255, 241, 66]),
      split_points: [1],
      expected_final_mode: @telnet.ParserMode::Normal,
    },
    ChunkFixture::{
      name: "split after IAC",
      wire: bytes([65, 255, 241, 66]),
      split_points: [2],
      expected_final_mode: @telnet.ParserMode::Normal,
    },
    ChunkFixture::{
      name: "split after WILL",
      wire: bytes([255, 251, 1]),
      split_points: [2],
      expected_final_mode: @telnet.ParserMode::Normal,
    },
    ChunkFixture::{
      name: "split before subneg option",
      wire: bytes([255, 250, 24, 1, 255, 240]),
      split_points: [2],
      expected_final_mode: @telnet.ParserMode::Normal,
    },
    ChunkFixture::{
      name: "split after subneg option",
      wire: bytes([255, 250, 24, 1, 255, 240]),
      split_points: [3],
      expected_final_mode: @telnet.ParserMode::Normal,
    },
    ChunkFixture::{
      name: "split before escaped IAC payload",
      wire: bytes([255, 250, 31, 0, 255, 255, 0, 24, 255, 240]),
      split_points: [5],
      expected_final_mode: @telnet.ParserMode::Normal,
    },
    ChunkFixture::{
      name: "split between escaped IAC pair",
      wire: bytes([255, 250, 31, 0, 255, 255, 0, 24, 255, 240]),
      split_points: [5, 6],
      expected_final_mode: @telnet.ParserMode::Normal,
    },
    ChunkFixture::{
      name: "split before SE",
      wire: bytes([255, 250, 24, 1, 255, 240]),
      split_points: [5],
      expected_final_mode: @telnet.ParserMode::Normal,
    },
  ]
  assert_true(cases.length() == 8)
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.wire.length() > 0)
    assert_true(c.split_points.length() >= 1)
    assert_true(c.expected_final_mode == @telnet.ParserMode::Normal)
  })
}

///|
test "encoder fixture corpus covers IAC escaping and command framing" {
  let cases = [
    EncoderFixture::{
      name: "plain data",
      item: @telnet.EncodeItem::EscapedData(span([65, 66, 67])),
      expected_wire: bytes([65, 66, 67]),
    },
    EncoderFixture::{
      name: "escape IAC in data",
      item: @telnet.EncodeItem::EscapedData(span([65, 255, 66])),
      expected_wire: bytes([65, 255, 255, 66]),
    },
    EncoderFixture::{
      name: "raw data bypass",
      item: @telnet.EncodeItem::RawData(span([255])),
      expected_wire: bytes([255]),
    },
    EncoderFixture::{
      name: "NOP command",
      item: @telnet.EncodeItem::Command(@telnet.Command::NOP),
      expected_wire: bytes([255, 241]),
    },
    EncoderFixture::{
      name: "GA command",
      item: @telnet.EncodeItem::Command(@telnet.Command::GA),
      expected_wire: bytes([255, 249]),
    },
    EncoderFixture::{
      name: "WILL ECHO",
      item: @telnet.EncodeItem::Negotiation(
        neg_event(@telnet.NegotiationVerb::Will, 1),
      ),
      expected_wire: bytes([255, 251, 1]),
    },
    EncoderFixture::{
      name: "WONT ECHO",
      item: @telnet.EncodeItem::Negotiation(
        neg_event(@telnet.NegotiationVerb::Wont, 1),
      ),
      expected_wire: bytes([255, 252, 1]),
    },
    EncoderFixture::{
      name: "DO NAWS",
      item: @telnet.EncodeItem::Negotiation(
        neg_event(@telnet.NegotiationVerb::Do, 31),
      ),
      expected_wire: bytes([255, 253, 31]),
    },
    EncoderFixture::{
      name: "DONT NAWS",
      item: @telnet.EncodeItem::Negotiation(
        neg_event(@telnet.NegotiationVerb::Dont, 31),
      ),
      expected_wire: bytes([255, 254, 31]),
    },
    EncoderFixture::{
      name: "TTYPE SEND",
      item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: opt(24),
        payload: span([1]),
      }),
      expected_wire: bytes([255, 250, 24, 1, 255, 240]),
    },
    EncoderFixture::{
      name: "NAWS 255x24 escapes payload IAC",
      item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: opt(31),
        payload: span([0, 255, 0, 24]),
      }),
      expected_wire: bytes([255, 250, 31, 0, 255, 255, 0, 24, 255, 240]),
    },
  ]
  assert_true(cases.length() == 11)
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.item == c.item)
    assert_true(c.expected_wire.length() > 0 || c.name == "empty")
  })
}

///|
test "NVT CR policy fixture corpus distinguishes preserve validate and normalize" {
  let preserve = @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
  let validate = @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::ValidateNvt,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
  let normalize = @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::NormalizeToLf,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
  assert_true(preserve.cr_policy == @telnet.CrPolicy::Preserve)
  assert_true(validate.cr_policy == @telnet.CrPolicy::ValidateNvt)
  assert_true(normalize.cr_policy == @telnet.CrPolicy::NormalizeToLf)
}

///|
test "buffer ownership fixtures make copy behavior testable" {
  let borrowed = @telnet.BufferSlice::{
    span: slice([65, 66, 67], 1, 2),
    ownership: @telnet.BufferOwnership::BorrowedInput,
  }
  let copied = @telnet.BufferSlice::{
    span: span([65, 66]),
    ownership: @telnet.BufferOwnership::Copied,
  }
  let scratch = @telnet.BufferSlice::{
    span: span([255]),
    ownership: @telnet.BufferOwnership::Scratch,
  }
  assert_true(borrowed.span.start == 1)
  assert_true(borrowed.span.length == 2)
  assert_true(copied.ownership == @telnet.BufferOwnership::Copied)
  assert_true(scratch.ownership == @telnet.BufferOwnership::Scratch)
}

///|
test "option payload fixtures cover TERMINAL-TYPE NAWS and START_TLS" {
  let ttype_send = @telnet.OptionPayload::TerminalType(
    @telnet.TerminalTypeMessage::Send,
  )
  let ttype_is = @telnet.OptionPayload::TerminalType(
    @telnet.TerminalTypeMessage::Is("xterm-256color"),
  )
  let naws = @telnet.OptionPayload::Naws(@telnet.NawsSize::{
    columns: (80).to_uint16(),
    rows: (24).to_uint16(),
  })
  let start_tls = @telnet.OptionPayload::StartTls(
    @telnet.StartTlsMessage::StartTls,
  )
  let follows = @telnet.OptionPayload::StartTls(
    @telnet.StartTlsMessage::Follows,
  )
  assert_true(ttype_send != ttype_is)
  assert_true(
    naws ==
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (80).to_uint16(),
      rows: (24).to_uint16(),
    }),
  )
  assert_true(start_tls != follows)
}

///|
test "option payload fixtures cover NEW-ENVIRON variants and escaped values" {
  let vars = [
    @telnet.EnvironmentVariable::{
      kind: @telnet.EnvironmentVariableKind::Var,
      name: "FOO",
      value: None,
    },
    @telnet.EnvironmentVariable::{
      kind: @telnet.EnvironmentVariableKind::UserVar,
      name: "BAR",
      value: Some("baz"),
    },
    @telnet.EnvironmentVariable::{
      kind: @telnet.EnvironmentVariableKind::Var,
      name: "FO\u{0002}O",
      value: Some("B\u{0001}AR"),
    },
  ]
  let is_msg = @telnet.OptionPayload::Environment(
    @telnet.EnvironmentMessage::Is(vars),
  )
  let send_msg = @telnet.OptionPayload::Environment(
    @telnet.EnvironmentMessage::Send(["FOO", "BAR"]),
  )
  let info_msg = @telnet.OptionPayload::Environment(
    @telnet.EnvironmentMessage::Info(vars),
  )
  assert_true(is_msg != send_msg)
  assert_true(is_msg != info_msg)
}

///|
test "option payload fixtures cover CHARSET negotiation" {
  let request = @telnet.OptionPayload::Charset(
    @telnet.CharsetMessage::Request(["UTF-8", "US-ASCII", "ISO-8859-1"]),
  )
  let accepted = @telnet.OptionPayload::Charset(
    @telnet.CharsetMessage::Accepted("UTF-8"),
  )
  let rejected = @telnet.OptionPayload::Charset(
    @telnet.CharsetMessage::Rejected,
  )
  let table = @telnet.OptionPayload::Charset(
    @telnet.CharsetMessage::TTableIs("latin1-to-unicode"),
  )
  assert_true(request != accepted)
  assert_true(accepted != rejected)
  assert_true(
    table !=
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableRejected),
  )
}

///|
test "option payload fixtures cover LINEMODE messages" {
  let mode = @telnet.OptionPayload::Linemode(
    @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
      flags: [
        @telnet.LinemodeModeFlag::Edit,
        @telnet.LinemodeModeFlag::TrapSig,
        @telnet.LinemodeModeFlag::ModeAck,
      ],
    }),
  )
  let default_mask = @telnet.OptionPayload::Linemode(
    @telnet.LinemodeMessage::ForwardMask(@telnet.LinemodeForwardMask::Default),
  )
  let no_mask = @telnet.OptionPayload::Linemode(
    @telnet.LinemodeMessage::ForwardMask(@telnet.LinemodeForwardMask::None),
  )
  let explicit_mask = @telnet.OptionPayload::Linemode(
    @telnet.LinemodeMessage::ForwardMask(
      @telnet.LinemodeForwardMask::Bytes(span([0, 10, 13])),
    ),
  )
  let slc = @telnet.OptionPayload::Linemode(
    @telnet.LinemodeMessage::Slc(span([1, 2, 3])),
  )
  assert_true(mode != default_mask)
  assert_true(default_mask != no_mask)
  assert_true(explicit_mask != slc)
}

///|
test "RFC 1143 negotiation fixture corpus covers WILL handling" {
  let no = @telnet.HalfState::No
  let yes = @telnet.HalfState::Yes
  let want_no_empty = @telnet.HalfState::WantNo(@telnet.QueueBit::Empty)
  let want_no_opp = @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite)
  let want_yes_empty = @telnet.HalfState::WantYes(@telnet.QueueBit::Empty)
  let cases = [
    NegotiationFixture::{
      name: "WILL accepted from NO",
      before: option_state(1, no, no),
      input: neg_event(@telnet.NegotiationVerb::Will, 1),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(1, no, yes),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Do, 1),
        ),
        @telnet.NegotiationAction::MarkEnabled(
          @telnet.OptionSide::Remote,
          opt(1),
        ),
      ],
    },
    NegotiationFixture::{
      name: "WILL rejected from NO",
      before: option_state(1, no, no),
      input: neg_event(@telnet.NegotiationVerb::Will, 1),
      decision: @telnet.PolicyDecision::Reject,
      after: option_state(1, no, no),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Dont, 1),
        ),
      ],
    },
    NegotiationFixture::{
      name: "duplicate WILL ignored from YES",
      before: option_state(1, no, yes),
      input: neg_event(@telnet.NegotiationVerb::Will, 1),
      decision: @telnet.PolicyDecision::Ignore,
      after: option_state(1, no, yes),
      actions: [@telnet.NegotiationAction::NoAction],
    },
    NegotiationFixture::{
      name: "WILL answers pending DO",
      before: option_state(31, no, want_yes_empty),
      input: neg_event(@telnet.NegotiationVerb::Will, 31),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(31, no, yes),
      actions: [
        @telnet.NegotiationAction::MarkEnabled(
          @telnet.OptionSide::Remote,
          opt(31),
        ),
      ],
    },
    NegotiationFixture::{
      name: "WILL during WANTNO empty disables",
      before: option_state(31, no, want_no_empty),
      input: neg_event(@telnet.NegotiationVerb::Will, 31),
      decision: @telnet.PolicyDecision::Ignore,
      after: option_state(31, no, no),
      actions: [@telnet.NegotiationAction::NoAction],
    },
    NegotiationFixture::{
      name: "WILL during WANTNO opposite queues DO",
      before: option_state(31, no, want_no_opp),
      input: neg_event(@telnet.NegotiationVerb::Will, 31),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(31, no, want_yes_empty),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Do, 31),
        ),
      ],
    },
  ]
  assert_true(cases.length() == 6)
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.decision == c.decision)
    assert_true(c.before.option == c.after.option)
  })
}

///|
test "RFC 1143 negotiation fixture corpus covers WONT handling" {
  let no = @telnet.HalfState::No
  let yes = @telnet.HalfState::Yes
  let want_no_empty = @telnet.HalfState::WantNo(@telnet.QueueBit::Empty)
  let want_no_opp = @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite)
  let want_yes_empty = @telnet.HalfState::WantYes(@telnet.QueueBit::Empty)
  let want_yes_opp = @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite)
  let cases = [
    NegotiationFixture::{
      name: "WONT from NO ignored",
      before: option_state(1, no, no),
      input: neg_event(@telnet.NegotiationVerb::Wont, 1),
      decision: @telnet.PolicyDecision::Ignore,
      after: option_state(1, no, no),
      actions: [@telnet.NegotiationAction::NoAction],
    },
    NegotiationFixture::{
      name: "WONT from YES must be acknowledged by DONT",
      before: option_state(1, no, yes),
      input: neg_event(@telnet.NegotiationVerb::Wont, 1),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(1, no, no),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Dont, 1),
        ),
        @telnet.NegotiationAction::MarkDisabled(
          @telnet.OptionSide::Remote,
          opt(1),
        ),
      ],
    },
    NegotiationFixture::{
      name: "WONT answers pending DO",
      before: option_state(31, no, want_yes_empty),
      input: neg_event(@telnet.NegotiationVerb::Wont, 31),
      decision: @telnet.PolicyDecision::Reject,
      after: option_state(31, no, no),
      actions: [
        @telnet.NegotiationAction::MarkDisabled(
          @telnet.OptionSide::Remote,
          opt(31),
        ),
      ],
    },
    NegotiationFixture::{
      name: "WONT answers pending DO with opposite request",
      before: option_state(31, no, want_yes_opp),
      input: neg_event(@telnet.NegotiationVerb::Wont, 31),
      decision: @telnet.PolicyDecision::Reject,
      after: option_state(31, no, want_no_empty),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Dont, 31),
        ),
      ],
    },
    NegotiationFixture::{
      name: "WONT during WANTNO empty confirms disabled",
      before: option_state(31, no, want_no_empty),
      input: neg_event(@telnet.NegotiationVerb::Wont, 31),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(31, no, no),
      actions: [
        @telnet.NegotiationAction::MarkDisabled(
          @telnet.OptionSide::Remote,
          opt(31),
        ),
      ],
    },
    NegotiationFixture::{
      name: "WONT during WANTNO opposite restarts enable",
      before: option_state(31, no, want_no_opp),
      input: neg_event(@telnet.NegotiationVerb::Wont, 31),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(31, no, want_yes_empty),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Do, 31),
        ),
      ],
    },
  ]
  assert_true(cases.length() == 6)
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.decision == c.decision)
    assert_true(c.input.verb == @telnet.NegotiationVerb::Wont)
  })
}

///|
test "RFC 1143 negotiation fixture corpus covers DO handling" {
  let no = @telnet.HalfState::No
  let yes = @telnet.HalfState::Yes
  let want_no_empty = @telnet.HalfState::WantNo(@telnet.QueueBit::Empty)
  let want_no_opp = @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite)
  let want_yes_empty = @telnet.HalfState::WantYes(@telnet.QueueBit::Empty)
  let cases = [
    NegotiationFixture::{
      name: "DO accepted from NO",
      before: option_state(1, no, no),
      input: neg_event(@telnet.NegotiationVerb::Do, 1),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(1, yes, no),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Will, 1),
        ),
        @telnet.NegotiationAction::MarkEnabled(
          @telnet.OptionSide::Local,
          opt(1),
        ),
      ],
    },
    NegotiationFixture::{
      name: "DO rejected from NO",
      before: option_state(46, no, no),
      input: neg_event(@telnet.NegotiationVerb::Do, 46),
      decision: @telnet.PolicyDecision::Reject,
      after: option_state(46, no, no),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Wont, 46),
        ),
      ],
    },
    NegotiationFixture::{
      name: "duplicate DO ignored from YES",
      before: option_state(1, yes, no),
      input: neg_event(@telnet.NegotiationVerb::Do, 1),
      decision: @telnet.PolicyDecision::Ignore,
      after: option_state(1, yes, no),
      actions: [@telnet.NegotiationAction::NoAction],
    },
    NegotiationFixture::{
      name: "DO answers pending WILL",
      before: option_state(31, want_yes_empty, no),
      input: neg_event(@telnet.NegotiationVerb::Do, 31),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(31, yes, no),
      actions: [
        @telnet.NegotiationAction::MarkEnabled(
          @telnet.OptionSide::Local,
          opt(31),
        ),
      ],
    },
    NegotiationFixture::{
      name: "DO during WANTNO empty disables",
      before: option_state(31, want_no_empty, no),
      input: neg_event(@telnet.NegotiationVerb::Do, 31),
      decision: @telnet.PolicyDecision::Ignore,
      after: option_state(31, no, no),
      actions: [@telnet.NegotiationAction::NoAction],
    },
    NegotiationFixture::{
      name: "DO during WANTNO opposite queues WILL",
      before: option_state(31, want_no_opp, no),
      input: neg_event(@telnet.NegotiationVerb::Do, 31),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(31, want_yes_empty, no),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Will, 31),
        ),
      ],
    },
  ]
  assert_true(cases.length() == 6)
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.decision == c.decision)
    assert_true(c.input.verb == @telnet.NegotiationVerb::Do)
  })
}

///|
test "RFC 1143 negotiation fixture corpus covers DONT handling" {
  let no = @telnet.HalfState::No
  let yes = @telnet.HalfState::Yes
  let want_no_empty = @telnet.HalfState::WantNo(@telnet.QueueBit::Empty)
  let want_no_opp = @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite)
  let want_yes_empty = @telnet.HalfState::WantYes(@telnet.QueueBit::Empty)
  let want_yes_opp = @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite)
  let cases = [
    NegotiationFixture::{
      name: "DONT from NO ignored",
      before: option_state(1, no, no),
      input: neg_event(@telnet.NegotiationVerb::Dont, 1),
      decision: @telnet.PolicyDecision::Ignore,
      after: option_state(1, no, no),
      actions: [@telnet.NegotiationAction::NoAction],
    },
    NegotiationFixture::{
      name: "DONT from YES must be acknowledged by WONT",
      before: option_state(1, yes, no),
      input: neg_event(@telnet.NegotiationVerb::Dont, 1),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(1, no, no),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Wont, 1),
        ),
        @telnet.NegotiationAction::MarkDisabled(
          @telnet.OptionSide::Local,
          opt(1),
        ),
      ],
    },
    NegotiationFixture::{
      name: "DONT answers pending WILL",
      before: option_state(31, want_yes_empty, no),
      input: neg_event(@telnet.NegotiationVerb::Dont, 31),
      decision: @telnet.PolicyDecision::Reject,
      after: option_state(31, no, no),
      actions: [
        @telnet.NegotiationAction::MarkDisabled(
          @telnet.OptionSide::Local,
          opt(31),
        ),
      ],
    },
    NegotiationFixture::{
      name: "DONT answers pending WILL with opposite request",
      before: option_state(31, want_yes_opp, no),
      input: neg_event(@telnet.NegotiationVerb::Dont, 31),
      decision: @telnet.PolicyDecision::Reject,
      after: option_state(31, want_no_empty, no),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Wont, 31),
        ),
      ],
    },
    NegotiationFixture::{
      name: "DONT during WANTNO empty confirms disabled",
      before: option_state(31, want_no_empty, no),
      input: neg_event(@telnet.NegotiationVerb::Dont, 31),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(31, no, no),
      actions: [
        @telnet.NegotiationAction::MarkDisabled(
          @telnet.OptionSide::Local,
          opt(31),
        ),
      ],
    },
    NegotiationFixture::{
      name: "DONT during WANTNO opposite restarts enable",
      before: option_state(31, want_no_opp, no),
      input: neg_event(@telnet.NegotiationVerb::Dont, 31),
      decision: @telnet.PolicyDecision::Accept,
      after: option_state(31, want_yes_empty, no),
      actions: [
        @telnet.NegotiationAction::Send(
          neg_event(@telnet.NegotiationVerb::Will, 31),
        ),
      ],
    },
  ]
  assert_true(cases.length() == 6)
  cases.each(fn(c) raise {
    assert_true(c.name.length() > 0)
    assert_true(c.decision == c.decision)
    assert_true(c.input.verb == @telnet.NegotiationVerb::Dont)
  })
}

///|
test "libtelnet-inspired RFC1143 ZMP fixture is represented" {
  let zmp = 93
  let enable_once = NegotiationFixture::{
    name: "enable ZMP emits DO",
    before: option_state(zmp, @telnet.HalfState::No, @telnet.HalfState::No),
    input: neg_event(@telnet.NegotiationVerb::Will, zmp),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(zmp, @telnet.HalfState::No, @telnet.HalfState::Yes),
    actions: [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Do, zmp),
      ),
    ],
  }
  let enable_again = NegotiationFixture::{
    name: "enable ZMP again emits nothing",
    before: option_state(zmp, @telnet.HalfState::No, @telnet.HalfState::Yes),
    input: neg_event(@telnet.NegotiationVerb::Will, zmp),
    decision: @telnet.PolicyDecision::Ignore,
    after: option_state(zmp, @telnet.HalfState::No, @telnet.HalfState::Yes),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  let disable_once = NegotiationFixture::{
    name: "disable ZMP emits DONT",
    before: option_state(zmp, @telnet.HalfState::No, @telnet.HalfState::Yes),
    input: neg_event(@telnet.NegotiationVerb::Wont, zmp),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(zmp, @telnet.HalfState::No, @telnet.HalfState::No),
    actions: [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, zmp),
      ),
    ],
  }
  assert_true(enable_once.actions.length() == 1)
  assert_true(enable_again.actions == [@telnet.NegotiationAction::NoAction])
  assert_true(disable_once.actions.length() == 1)
}
