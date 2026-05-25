// Invalid command split matrix for strict and lenient parser configurations.
// Current behavior reports InvalidCommandByte and resumes deterministically in
// both modes; these tests characterize split-boundary parity with whole-buffer
// parsing and finish() recovery.

///|
fn invalid_command_split_config(strict : Bool) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: strict,
  }
}

///|
fn invalid_command_split_feed_two(
  config : @telnet.ParserConfig,
  wire : Array[Int],
  split : Int,
) -> (@telnet.ParserFeedResult, Array[@telnet.Event]) {
  let first = @telnet.Parser::new(config).feed_span(@telnet.ByteSpan::{
    bytes: bytes(wire),
    start: 0,
    length: split,
  })
  let second = first.parser.feed_span(@telnet.ByteSpan::{
    bytes: bytes(wire),
    start: split,
    length: wire.length() - split,
  })
  (second, first.events + second.events)
}

///|
fn invalid_command_split_assert_case(
  wire : Array[Int],
  split : Int,
  expected : Array[@telnet.Event],
) -> Unit raise {
  [true, false].each(fn(strict) raise {
    let config = invalid_command_split_config(strict)
    let whole = @telnet.Parser::new(config).feed(bytes(wire))
    assert_true(whole.bytes_consumed == wire.length())
    assert_true(events_semantically_equal(whole.events, expected))
    assert_true(whole.parser.checkpoint.mode == @telnet.ParserMode::Normal)
    let whole_done = whole.parser.finish()
    assert_true(whole_done.complete)
    assert_true(whole_done.events == [])

    let (split_result, split_events) = invalid_command_split_feed_two(
      config, wire, split,
    )
    assert_true(
      split_result.parser.checkpoint.mode == @telnet.ParserMode::Normal,
    )
    assert_true(events_semantically_equal(split_events, whole.events))
    assert_true(events_semantically_equal(split_events, expected))
    let split_done = split_result.parser.finish()
    assert_true(split_done.complete)
    assert_true(split_done.events == [])
  })
}

///|
test "invalid command split after dangling IAC recovers in both modes" {
  invalid_command_split_assert_case([255, 42], 1, [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(42)),
  ])
}

///|
test "invalid command split with data before and after recovers in both modes" {
  invalid_command_split_assert_case([65, 255, 42, 66], 2, [
    data([65]),
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 2, Some(42)),
    data([66]),
  ])
}

///|
test "invalid command split before valid command recovers in both modes" {
  invalid_command_split_assert_case([255, 42, 255, 241], 2, [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(42)),
    cmd(@telnet.Command::NOP),
  ])
}

///|
test "invalid command split before escaped IAC data recovers in both modes" {
  invalid_command_split_assert_case([255, 42, 255, 255], 2, [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(42)),
    data([255]),
  ])
}

///|
test "invalid command split inside SB after IAC recovers in both modes" {
  invalid_command_split_assert_case(
    [255, 250, 24, 1, 255, 42, 2, 255, 240],
    5,
    [
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 5, Some(42)),
      sb(24, [1, 2]),
    ],
  )
}

///|
test "invalid command split immediately before negotiation recovers in both modes" {
  invalid_command_split_assert_case([65, 255, 42, 255, 251, 1, 66], 3, [
    data([65]),
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 2, Some(42)),
    neg(@telnet.NegotiationVerb::Will, 1),
    data([66]),
  ])
}
