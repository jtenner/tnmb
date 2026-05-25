// Subnegotiation malformed/recovery matrix. These cases lock parser behavior
// around commands embedded in SB payloads, oversized discard, and stream resume.

///|
fn sb_recovery_assert(
  wire : Array[Int],
  expected : Array[@telnet.Event],
) -> Unit raise {
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.bytes_consumed == wire.length())
  assert_true(result.events == expected)
  assert_true(result.parser.checkpoint.mode == @telnet.ParserMode::Normal)
}

///|
test "subnegotiation recovery invalid WILL inside SB resumes and keeps option byte as payload" {
  sb_recovery_assert([255, 250, 24, 1, 255, 251, 1, 255, 240, 65], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 5, Some(251)),
    sb(24, [1, 1]),
    data([65]),
  ])
}

///|
test "subnegotiation recovery invalid DO inside SB resumes and keeps option byte as payload" {
  sb_recovery_assert([255, 250, 24, 1, 255, 253, 31, 255, 240, 66], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 5, Some(253)),
    sb(24, [1, 31]),
    data([66]),
  ])
}

///|
test "subnegotiation recovery nested SB byte is reported and payload continues" {
  sb_recovery_assert([255, 250, 24, 255, 250, 31, 255, 240], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 4, Some(250)),
    sb(24, [31]),
  ])
}

///|
test "subnegotiation recovery escaped SE stays payload until real terminator" {
  sb_recovery_assert([255, 250, 42, 1, 255, 255, 240, 255, 240, 67], [
    sb(42, [1, 255, 240]),
    data([67]),
  ])
}

///|
test "subnegotiation recovery oversized discard resumes after SE and parses next command" {
  let parser = @telnet.Parser::new(@telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 3,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  })
  let result = parser.feed(
    bytes([255, 250, 39, 65, 66, 67, 68, 255, 240, 255, 241]),
  )
  assert_true(
    result.events ==
    [
      err(@telnet.TelnetErrorKind::SubnegotiationTooLarge, 6, Some(68)),
      cmd(@telnet.Command::NOP),
    ],
  )
  assert_true(result.parser.checkpoint.mode == @telnet.ParserMode::Normal)
}

///|
test "subnegotiation recovery invalid command before SE still emits decoded payload" {
  sb_recovery_assert([255, 250, 24, 65, 255, 242, 66, 255, 240], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 5, Some(242)),
    sb(24, [65, 66]),
  ])
}

///|
fn sb_overflow_config(max_sb : Int) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: max_sb,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
fn sb_overflow_feed_chunks(
  chunks : Array[Array[Int]],
  expected : Array[@telnet.Event],
) -> Unit raise {
  let mut parser = @telnet.Parser::new(sb_overflow_config(3))
  let mut events : Array[@telnet.Event] = []
  chunks.each(fn(chunk) raise {
    let r = parser.feed(bytes(chunk))
    assert_true(r.bytes_consumed == chunk.length())
    events = events + r.events
    parser = r.parser
  })
  let finished = parser.finish()
  assert_true(finished.events.length() == 0)
  assert_true(events_semantically_equal(events, expected))
  assert_true(events.length() <= expected.length())
}

///|
fn sb_overflow_assert_discarded_once(
  chunks : Array[Array[Int]],
  expected : Array[@telnet.Event],
) -> Unit raise {
  sb_overflow_feed_chunks(chunks, expected)
  let mut overflow_count = 0
  let mut success_count = 0
  expected.each(fn(event) {
    match event {
      Error(e) =>
        if e.kind == @telnet.TelnetErrorKind::SubnegotiationTooLarge {
          overflow_count = overflow_count + 1
        }
      Subnegotiation(_) => success_count = success_count + 1
      _ => ()
    }
  })
  assert_true(overflow_count == 1)
  assert_true(success_count == 0)
}

///|
test "subnegotiation overflow exact max split before SE succeeds" {
  sb_overflow_feed_chunks([[255, 250, 39, 65, 66, 67, 255], [240, 90]], [
    sb(39, [65, 66, 67]),
    data([90]),
  ])
}

///|
test "subnegotiation overflow byte in later feed discards until SE and resumes" {
  sb_overflow_assert_discarded_once(
    [[255, 250, 39, 65, 66, 67], [68, 255, 240, 255, 241]],
    [
      err(@telnet.TelnetErrorKind::SubnegotiationTooLarge, 6, Some(68)),
      cmd(@telnet.Command::NOP),
    ],
  )
}

///|
test "subnegotiation overflow on escaped IAC pair in later feed" {
  sb_overflow_assert_discarded_once(
    [[255, 250, 39, 65, 66, 67, 255], [255, 255, 240, 88]],
    [
      err(@telnet.TelnetErrorKind::SubnegotiationTooLarge, 7, Some(255)),
      data([88]),
    ],
  )
}

///|
test "subnegotiation overflow discard ignores later payload and terminates on SE" {
  sb_overflow_assert_discarded_once(
    [[255, 250, 39, 65, 66, 67, 68], [69, 70, 255, 240, 71]],
    [
      err(@telnet.TelnetErrorKind::SubnegotiationTooLarge, 6, Some(68)),
      data([71]),
    ],
  )
}

///|
test "subnegotiation overflow discard reports invalid IAC command then resumes" {
  sb_overflow_assert_discarded_once(
    [[255, 250, 39, 65, 66, 67, 68], [255, 242, 69, 255, 240, 255, 241]],
    [
      err(@telnet.TelnetErrorKind::SubnegotiationTooLarge, 6, Some(68)),
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 8, Some(242)),
      cmd(@telnet.Command::NOP),
    ],
  )
}
