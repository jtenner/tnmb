// Named deterministic fuzz-seed regressions.
//
// Each case is small enough to review manually but was chosen from categories
// that fuzzing and target-parity runs should keep stable across wasm/js/native.

///|
fn named_seed_parse_all(
  config : @telnet.ParserConfig,
  wire : Array[Int],
) -> Array[@telnet.Event] raise {
  let fed = @telnet.Parser::new(config).feed(bytes(wire))
  assert_true(fed.bytes_consumed == wire.length())
  let finished = fed.parser.finish()
  fed.events + finished.events
}

///|
fn named_seed_small_sb_config(max_sb : Int) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: max_sb,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
fn named_seed_cr_config(policy : @telnet.CrPolicy) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: policy,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
test "named fuzz seed dense escaped IAC stream preserves literal 255 bytes" {
  let events = named_seed_parse_all(preserve_config(), [
    65, 255, 255, 255, 255, 255, 241, 66,
  ])
  assert_true(
    fuzz_normalize_events(events) ==
    [
      FuzzObservedEvent::Data(bytes([65, 255, 255])),
      FuzzObservedEvent::Command(@telnet.Command::NOP),
      FuzzObservedEvent::Data(bytes([66])),
    ],
  )

  let payload = span([65, 255, 255, 66])
  let output = Bytes::new(
    @telnet.Encoder::canonical().required_capacity(
      @telnet.EncodeItem::EscapedData(payload),
    ),
  )
  let encoded = @telnet.Encoder::canonical().encode_item(
    @telnet.EncodeItem::EscapedData(payload),
    output,
  )
  match encoded {
    Ok(result) => {
      assert_true(result.bytes_written == 6)
      assert_true(result.required_capacity == 6)
    }
    Err(_) => assert_true(false)
  }
  assert_true(output == bytes([65, 255, 255, 255, 255, 66]))
}

///|
test "named fuzz seed nested-looking SB bytes are payload after recovery" {
  let events = named_seed_parse_all(preserve_config(), [
    255, 250, 24, 1, 255, 250, 31, 255, 255, 240, 255, 240,
  ])
  assert_true(
    events ==
    [
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 5, Some(250)),
      sb(24, [1, 31, 255, 240]),
    ],
  )
}

///|
test "named fuzz seed invalid command recovers before valid command" {
  let strict_events = named_seed_parse_all(preserve_config(), [
    255, 200, 255, 241,
  ])
  assert_true(
    strict_events ==
    [
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(200)),
      cmd(@telnet.Command::NOP),
    ],
  )

  let lenient = @telnet.ParserConfig::{
    ..preserve_config(),
    strict_commands: false,
  }
  let lenient_events = named_seed_parse_all(lenient, [255, 200, 255, 241])
  assert_true(
    lenient_events ==
    [
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(200)),
      cmd(@telnet.Command::NOP),
    ],
  )
}

///|
test "named fuzz seed CR split cases stay policy-specific" {
  let preserve = @telnet.Parser::new(
    named_seed_cr_config(@telnet.CrPolicy::Preserve),
  )
  let preserve_first = preserve.feed(bytes([65, 13]))
  assert_true(
    events_semantically_equal(preserve_first.events, [data([65, 13])]),
  )
  let preserve_second = preserve_first.parser.feed(bytes([10, 66]))
  let preserve_done = preserve_second.parser.finish()
  assert_true(
    events_semantically_equal(
      preserve_first.events + preserve_second.events + preserve_done.events,
      [data([65, 13]), data([10, 66])],
    ),
  )

  let validate = @telnet.Parser::new(
    named_seed_cr_config(@telnet.CrPolicy::ValidateNvt),
  )
  let validate_first = validate.feed(bytes([13]))
  let validate_second = validate_first.parser.feed(bytes([10]))
  assert_true(validate_first.events.length() == 0)
  assert_true(validate_second.events == [data([13, 10])])

  let normalize = @telnet.Parser::new(
    named_seed_cr_config(@telnet.CrPolicy::NormalizeToLf),
  )
  let normalize_first = normalize.feed(bytes([13]))
  let normalize_second = normalize_first.parser.feed(bytes([0]))
  assert_true(normalize_first.events.length() == 0)
  assert_true(normalize_second.events == [data([13])])
}

///|
test "named fuzz seed mixed negotiation SB and data stream keeps ordering" {
  let events = named_seed_parse_all(preserve_config(), [
    65, 255, 251, 1, 255, 250, 31, 0, 80, 0, 24, 255, 240, 255, 255, 66,
  ])
  assert_true(
    fuzz_normalize_events(events) ==
    [
      FuzzObservedEvent::Data(bytes([65])),
      FuzzObservedEvent::Negotiation(
        neg_event(@telnet.NegotiationVerb::Will, 1),
      ),
      FuzzObservedEvent::Subnegotiation(opt(31), bytes([0, 80, 0, 24])),
      FuzzObservedEvent::Data(bytes([255, 66])),
    ],
  )
}

///|
test "named fuzz seed oversized SB discards then resumes at later command" {
  let events = named_seed_parse_all(named_seed_small_sb_config(2), [
    255, 250, 39, 1, 2, 3, 255, 240, 255, 241, 90,
  ])
  assert_true(
    events ==
    [
      err(@telnet.TelnetErrorKind::SubnegotiationTooLarge, 5, Some(3)),
      cmd(@telnet.Command::NOP),
      data([90]),
    ],
  )
}

///|
test "named fuzz seed unknown raw SB preserves high bytes through parser codec and encoder" {
  let events = named_seed_parse_all(preserve_config(), [
    255, 250, 201, 128, 254, 255, 255, 255, 240,
  ])
  assert_true(events == [sb(201, [128, 254, 255])])

  let raw_payload = span([128, 254, 255])
  let decoded = @telnet.OptionPayload::decode(opt(201), raw_payload)
  assert_true(decoded == Ok(@telnet.OptionPayload::Raw(opt(201), raw_payload)))

  let payload_output = Bytes::new(3)
  let payload_encoded = @telnet.OptionPayload::encode(
    @telnet.OptionPayload::Raw(opt(201), raw_payload),
    payload_output,
  )
  assert_true(
    payload_encoded ==
    Ok(@telnet.EncodeResult::{ bytes_written: 3, required_capacity: 3 }),
  )
  assert_true(payload_output == bytes([128, 254, 255]))

  let sub_event = @telnet.SubnegotiationEvent::{
    option: opt(201),
    payload: raw_payload,
  }
  let wire_output = Bytes::new(9)
  let wire_encoded = @telnet.Encoder::new().encode_item(
    @telnet.EncodeItem::Subnegotiation(sub_event),
    wire_output,
  )
  assert_true(
    wire_encoded ==
    Ok(@telnet.EncodeResult::{ bytes_written: 9, required_capacity: 9 }),
  )
  assert_true(
    wire_output == bytes([255, 250, 201, 128, 254, 255, 255, 255, 240]),
  )
}
