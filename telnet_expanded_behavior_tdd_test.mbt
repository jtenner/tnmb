// Expanded behavioral tests for blind spots in the public TELNET API.
// These exercise production parser, encoder, negotiator, and codec behavior.

///|
fn tdd_bytes_slice(ns : Array[Int], start : Int, length : Int) -> Bytes {
  let out = Array::make(length, byte(0))
  for i = 0; i < length; i = i + 1 {
    out[i] = byte(ns[start + i])
  }
  Bytes::from_array(out)
}

///|
fn tdd_feed_split(
  config : @telnet.ParserConfig,
  wire : Array[Int],
  split : Int,
) -> Array[@telnet.Event] {
  let parser = @telnet.Parser::new(config)
  let first = parser.feed(tdd_bytes_slice(wire, 0, split))
  let second = first.parser.feed(
    tdd_bytes_slice(wire, split, wire.length() - split),
  )
  first.events + second.events
}

///|
fn tdd_feed_one_byte_at_a_time(
  config : @telnet.ParserConfig,
  wire : Array[Int],
) -> Array[@telnet.Event] {
  let mut parser = @telnet.Parser::new(config)
  let mut events : Array[@telnet.Event] = []
  for i = 0; i < wire.length(); i = i + 1 {
    let r = parser.feed(bytes([wire[i]]))
    events = events + r.events
    parser = r.parser
  }
  events
}

///|
fn tdd_assert_all_splits_equal(
  config : @telnet.ParserConfig,
  wire : Array[Int],
) -> Unit raise {
  let all_at_once = @telnet.Parser::new(config).feed(bytes(wire)).events
  for split = 0; split <= wire.length(); split = split + 1 {
    assert_true(tdd_feed_split(config, wire, split) == all_at_once)
  }
  assert_true(tdd_feed_one_byte_at_a_time(config, wire) == all_at_once)
}

///|
fn tdd_config(
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
fn tdd_expect_parse(
  config : @telnet.ParserConfig,
  wire : Array[Int],
  expected : Array[@telnet.Event],
) -> Unit raise {
  let result = @telnet.Parser::new(config).feed(bytes(wire))
  assert_true(result.events == expected)
  assert_true(result.bytes_consumed == wire.length())
}

///|
fn tdd_expect_finish(
  config : @telnet.ParserConfig,
  wire : Array[Int],
  expected_feed : Array[@telnet.Event],
  expected_finish : Array[@telnet.Event],
) -> Unit raise {
  let fed = @telnet.Parser::new(config).feed(bytes(wire))
  assert_true(fed.events == expected_feed)
  let done = fed.parser.finish()
  assert_true(done.events == expected_finish)
}

///|
fn tdd_assert_encode_ok(
  encoder : @telnet.Encoder,
  item : @telnet.EncodeItem,
  capacity : Int,
  expected_prefix : Array[Int],
  sentinel : Int,
) -> Unit raise {
  let output = Bytes::make(capacity, byte(sentinel))
  let encoded = encoder.encode_item(item, output)
  match encoded {
    Ok(r) => {
      assert_true(r.bytes_written == expected_prefix.length())
      assert_true(r.required_capacity == expected_prefix.length())
      for i = 0; i < expected_prefix.length(); i = i + 1 {
        assert_true(output[i] == byte(expected_prefix[i]))
      }
      for i = expected_prefix.length(); i < capacity; i = i + 1 {
        assert_true(output[i] == byte(sentinel))
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
fn tdd_assert_encode_too_small_atomic(
  item : @telnet.EncodeItem,
  capacity : Int,
  sentinel : Int,
) -> Unit raise {
  let encoder = @telnet.Encoder::canonical()
  let output = Bytes::make(capacity, byte(sentinel))
  let encoded = encoder.encode_item(item, output)
  match encoded {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      for i = 0; i < capacity; i = i + 1 {
        assert_true(output[i] == byte(sentinel))
      }
    }
  }
}

///|
test "TDD parser all split points are equivalent for representative streams" {
  let config = tdd_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    true,
    4096,
    8192,
  )
  let wires = [
    [255, 255],
    [255, 241],
    [255, 251, 1],
    [255, 250, 24, 1, 255, 240],
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    [65, 255, 246, 66],
  ]
  wires.each(fn(wire) raise { tdd_assert_all_splits_equal(config, wire) })
}

///|
test "TDD parser CR preserve policy keeps RFC854 wire bytes" {
  let config = tdd_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    true,
    4096,
    8192,
  )
  tdd_expect_parse(config, [13, 10], [data([13, 10])])
  tdd_expect_parse(config, [13, 0], [data([13, 0])])
  tdd_expect_parse(config, [13, 88], [data([13, 88])])
  tdd_expect_parse(config, [13, 255, 241], [
    data([13]),
    cmd(@telnet.Command::NOP),
  ])
}

///|
test "TDD parser CR validate policy rejects bad CR and recovers" {
  let config = tdd_config(
    @telnet.CrPolicy::ValidateNvt,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    true,
    4096,
    8192,
  )
  tdd_expect_parse(config, [13, 10], [data([13, 10])])
  tdd_expect_parse(config, [13, 0], [data([13, 0])])
  tdd_expect_parse(config, [13, 88, 13, 10], [
    err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(88)),
    data([88]),
    data([13, 10]),
  ])
  tdd_expect_finish(config, [13], [], [
    err(@telnet.TelnetErrorKind::PolicyRejected, 0, Some(13)),
  ])
}

///|
test "TDD parser CR normalize policy emits LF and handles chunk boundary" {
  let config = tdd_config(
    @telnet.CrPolicy::NormalizeToLf,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    true,
    4096,
    8192,
  )
  tdd_expect_parse(config, [13, 10], [data([10])])
  tdd_expect_parse(config, [13, 0], [data([13])])
  let parser = @telnet.Parser::new(config)
  let first = parser.feed(bytes([13]))
  assert_true(first.events == [])
  let second = first.parser.feed(bytes([10]))
  assert_true(second.events == [data([10])])
}

///|
test "TDD parser data coalescing policies are observable" {
  tdd_expect_parse(
    tdd_config(
      @telnet.CrPolicy::Preserve,
      @telnet.DataCoalescing::EmitImmediately,
      true,
      4096,
      8192,
    ),
    [65, 66, 67],
    [data([65]), data([66]), data([67])],
  )
  tdd_expect_parse(
    tdd_config(
      @telnet.CrPolicy::Preserve,
      @telnet.DataCoalescing::CoalesceUntilCommand,
      true,
      4096,
      8192,
    ),
    [65, 66, 255, 241, 67],
    [data([65, 66]), cmd(@telnet.Command::NOP), data([67])],
  )
  tdd_expect_parse(
    tdd_config(
      @telnet.CrPolicy::Preserve,
      @telnet.DataCoalescing::CoalesceUntilCapacity,
      true,
      2,
      8192,
    ),
    [65, 66, 67, 68],
    [data([65, 66]), data([67, 68])],
  )
}

///|
test "TDD parser strict invalid IAC commands and recovery" {
  let config = tdd_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    true,
    4096,
    8192,
  )
  let cases = [0, 1, 42, 239]
  cases.each(fn(n) raise {
    tdd_expect_parse(config, [255, n], [
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(n)),
    ])
  })
  tdd_expect_parse(config, [255, 42, 65, 255, 241], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(42)),
    data([65]),
    cmd(@telnet.Command::NOP),
  ])
  tdd_expect_parse(config, [255, 240], [
    err(@telnet.TelnetErrorKind::UnexpectedSubnegotiationEnd, 1, Some(240)),
  ])
}

///|
test "TDD parser lenient invalid IAC commands recover without aborting" {
  let config = tdd_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    false,
    4096,
    8192,
  )
  tdd_expect_parse(config, [65, 255, 42, 66, 255, 241], [
    data([65]),
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 2, Some(42)),
    data([66]),
    cmd(@telnet.Command::NOP),
  ])
}

///|
test "TDD parser malformed subnegotiation commands recover predictably" {
  let config = tdd_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    true,
    4096,
    6,
  )
  tdd_expect_parse(config, [255, 250, 24, 1, 255, 241, 255, 240], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 5, Some(241)),
    sb(24, [1]),
  ])
  tdd_expect_parse(config, [255, 250, 24, 1, 255, 251, 1, 255, 240], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 5, Some(251)),
    sb(24, [1, 1]),
  ])
  tdd_expect_parse(config, [255, 250, 24, 255, 250, 31, 255, 240], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 4, Some(250)),
    sb(24, [31]),
  ])
  tdd_expect_parse(config, [255, 250, 24, 255, 255, 240, 255, 240], [
    sb(24, [255, 240]),
  ])
  tdd_expect_finish(
    config,
    [255, 250, 24, 65, 66, 67, 68, 69, 70, 71],
    [err(@telnet.TelnetErrorKind::SubnegotiationTooLarge, 9, Some(71))],
    [],
  )
}

///|
test "TDD negotiator receive covers queued Q-method states" {
  let states = [
    @telnet.HalfState::No,
    @telnet.HalfState::Yes,
    @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
  ]
  states.each(fn(s) raise {
    let n = @telnet.Negotiator::with_states([
      option_state(31, @telnet.HalfState::No, s),
    ])
    let t = n.receive(
      neg_event(@telnet.NegotiationVerb::Will, 31),
      @telnet.PolicyDecision::Accept,
    )
    assert_true(t.before.remote_state == s)
    assert_true(t.after.option == opt(31))
  })
}

///|
test "TDD negotiator local request duplicate and opposite queue behavior" {
  let enabled = @telnet.Negotiator::with_states([
    option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
  ])
  let duplicate_enable = enabled.request(
    opt(1),
    @telnet.OptionSide::Local,
    true,
  )
  assert_true(duplicate_enable.after.local_state == @telnet.HalfState::Yes)
  assert_true(duplicate_enable.actions == [@telnet.NegotiationAction::NoAction])

  let pending = @telnet.Negotiator::with_states([
    option_state(
      1,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
  ])
  let opposite = pending.request(opt(1), @telnet.OptionSide::Local, false)
  assert_true(
    opposite.after.local_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
  )
  assert_true(opposite.actions == [@telnet.NegotiationAction::NoAction])
}

///|
test "TDD negotiator apply updates state_for" {
  let n = @telnet.Negotiator::new()
  let t = n.request(opt(31), @telnet.OptionSide::Remote, true)
  let after = n.apply(t)
  assert_true(after.state_for(opt(31)) == t.after)
  assert_true(
    after.state_for(opt(1)) ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
  )
}

///|
test "TDD encoder output buffer atomicity and trailing bytes" {
  tdd_assert_encode_too_small_atomic(
    @telnet.EncodeItem::EscapedData(span([65, 255, 66])),
    3,
    170,
  )
  tdd_assert_encode_ok(
    @telnet.Encoder::canonical(),
    @telnet.EncodeItem::EscapedData(span([65, 255, 66])),
    8,
    [65, 255, 255, 66],
    204,
  )
}

///|
test "TDD encoder canonical rejects raw TELNET command tokens as commands" {
  let encoder = @telnet.Encoder::canonical()
  let forbidden = [
    @telnet.Command::SB,
    @telnet.Command::WILL,
    @telnet.Command::WONT,
    @telnet.Command::DO,
    @telnet.Command::DONT,
    @telnet.Command::IAC,
  ]
  forbidden.each(fn(c) raise {
    let out = Bytes::make(3, byte(85))
    match encoder.encode_item(@telnet.EncodeItem::Command(c), out) {
      Ok(_) => assert_true(false)
      Err(e) =>
        assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
    }
    assert_true(out[0] == byte(85))
  })
}

///|
test "TDD encoder RawData bypass does not escape IAC" {
  tdd_assert_encode_ok(
    @telnet.Encoder::new(),
    @telnet.EncodeItem::RawData(span([65, 255, 66])),
    4,
    [65, 255, 66],
    0,
  )
}

///|
test "TDD encoder required capacity formulas cover representative lengths" {
  let encoder = @telnet.Encoder::canonical()
  let no_iac_4096 = Bytes::make(4096, byte(65))
  let all_iac_4096 = Bytes::make(4096, byte(255))
  assert_true(
    encoder.required_capacity(@telnet.EncodeItem::EscapedData(span([]))) == 0,
  )
  assert_true(
    encoder.required_capacity(@telnet.EncodeItem::EscapedData(span([255]))) == 2,
  )
  assert_true(
    encoder.required_capacity(@telnet.EncodeItem::EscapedData(span([65, 255]))) ==
    3,
  )
  assert_true(
    encoder.required_capacity(
      @telnet.EncodeItem::EscapedData(@telnet.ByteSpan::{
        bytes: no_iac_4096,
        start: 0,
        length: 4096,
      }),
    ) ==
    4096,
  )
  assert_true(
    encoder.required_capacity(
      @telnet.EncodeItem::EscapedData(@telnet.ByteSpan::{
        bytes: all_iac_4096,
        start: 0,
        length: 4096,
      }),
    ) ==
    8192,
  )
  assert_true(
    encoder.required_capacity(
      @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: opt(31),
        payload: span([]),
      }),
    ) ==
    5,
  )
  assert_true(
    encoder.required_capacity(
      @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: opt(31),
        payload: @telnet.ByteSpan::{
          bytes: all_iac_4096,
          start: 0,
          length: 4096,
        },
      }),
    ) ==
    8197,
  )
}

///|
test "TDD option codecs reject malformed TTYPE and NAWS and accept NAWS extremes" {
  match @telnet.TerminalTypeMessage::decode(span([])) {
    Ok(_) => assert_true(false)
    Err(e) =>
      assert_true(e.kind == @telnet.TelnetErrorKind::IncompleteSubnegotiation)
  }
  match @telnet.TerminalTypeMessage::decode(span([0])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::PolicyRejected)
  }
  match @telnet.NawsSize::decode(span([0, 80, 0])) {
    Ok(_) => assert_true(false)
    Err(e) =>
      assert_true(e.kind == @telnet.TelnetErrorKind::IncompleteSubnegotiation)
  }
  match @telnet.NawsSize::decode(span([0, 0, 0, 0])) {
    Ok(size) =>
      assert_true(
        size ==
        @telnet.NawsSize::{ columns: (0).to_uint16(), rows: (0).to_uint16() },
      )
    Err(_) => assert_true(false)
  }
  match @telnet.NawsSize::decode(span([255, 255, 255, 255])) {
    Ok(size) =>
      assert_true(
        size ==
        @telnet.NawsSize::{
          columns: (65535).to_uint16(),
          rows: (65535).to_uint16(),
        },
      )
    Err(_) => assert_true(false)
  }
}

///|
test "TDD option codecs cover NEW-ENVIRON CHARSET LINEMODE START_TLS malformations" {
  match @telnet.EnvironmentMessage::decode(span([0, 2])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::InvalidOptionByte)
  }
  match @telnet.CharsetMessage::decode(span([1, 59])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::PolicyRejected)
  }
  match @telnet.LinemodeMessage::decode(span([3, 1, 2])) {
    Ok(payload) =>
      assert_true(payload == @telnet.LinemodeMessage::Slc(span([1, 2])))
    Err(_) => assert_true(false)
  }
  match @telnet.LinemodeMessage::decode(span([2, 0, 1, 255])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.LinemodeMessage::ForwardMask(
          @telnet.LinemodeForwardMask::Bytes(span([0, 1, 255])),
        ),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.StartTlsMessage::decode(span([2])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::InvalidOptionByte)
  }
  match @telnet.StartTlsMessage::decode(span([1, 0])) {
    Ok(_) => assert_true(false)
    Err(e) => assert_true(e.kind == @telnet.TelnetErrorKind::PolicyRejected)
  }
}

///|
test "TDD mapping helpers cover command and option ranges" {
  for b = 240; b <= 255; b = b + 1 {
    match @telnet.Command::from_byte(byte(b)) {
      Some(c) => assert_true(c.to_byte() == byte(b))
      None => assert_true(false)
    }
  }
  let invalid = [0, 1, 42, 100, 239]
  invalid.each(fn(b) raise {
    assert_true(@telnet.Command::from_byte(byte(b)) == None)
  })
  let known = [0, 1, 3, 24, 31, 34, 36, 39, 42, 46, 255]
  known.each(fn(b) raise {
    let code = opt(b)
    assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
  })
  assert_true(@telnet.KnownOption::Unknown(opt(200)).to_code() == opt(200))
}
