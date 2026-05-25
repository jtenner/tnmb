// Lenient parser matrix: invalid IAC command bytes must be reported with exact
// offsets and parsing must resume at following data/commands.

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
fn lenient_assert_invalid_recovers(n : Int) -> Unit raise {
  let result = @telnet.Parser::new(lenient_config()).feed(
    bytes([65, 255, n, 66, 255, 241]),
  )
  assert_true(result.bytes_consumed == 6)
  assert_true(
    result.events ==
    [
      data([65]),
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 2, Some(n)),
      data([66]),
      cmd(@telnet.Command::NOP),
    ],
  )
  assert_true(result.parser.checkpoint.mode == @telnet.ParserMode::Normal)
}

///|
test "lenient matrix invalid IAC byte 0 recovers" {
  lenient_assert_invalid_recovers(0)
}

///|
test "lenient matrix invalid IAC byte 1 recovers" {
  lenient_assert_invalid_recovers(1)
}

///|
test "lenient matrix invalid IAC byte 2 recovers" {
  lenient_assert_invalid_recovers(2)
}

///|
test "lenient matrix invalid IAC byte 3 recovers" {
  lenient_assert_invalid_recovers(3)
}

///|
test "lenient matrix invalid IAC byte 4 recovers" {
  lenient_assert_invalid_recovers(4)
}

///|
test "lenient matrix invalid IAC byte 5 recovers" {
  lenient_assert_invalid_recovers(5)
}

///|
test "lenient matrix invalid IAC byte 6 recovers" {
  lenient_assert_invalid_recovers(6)
}

///|
test "lenient matrix invalid IAC byte 7 recovers" {
  lenient_assert_invalid_recovers(7)
}

///|
test "lenient matrix invalid IAC byte 8 recovers" {
  lenient_assert_invalid_recovers(8)
}

///|
test "lenient matrix invalid IAC byte 9 recovers" {
  lenient_assert_invalid_recovers(9)
}

///|
test "lenient matrix invalid IAC byte 10 recovers" {
  lenient_assert_invalid_recovers(10)
}

///|
test "lenient matrix invalid IAC byte 11 recovers" {
  lenient_assert_invalid_recovers(11)
}

///|
test "lenient matrix invalid IAC byte 12 recovers" {
  lenient_assert_invalid_recovers(12)
}

///|
test "lenient matrix invalid IAC byte 13 recovers" {
  lenient_assert_invalid_recovers(13)
}

///|
test "lenient matrix invalid IAC byte 14 recovers" {
  lenient_assert_invalid_recovers(14)
}

///|
test "lenient matrix invalid IAC byte 15 recovers" {
  lenient_assert_invalid_recovers(15)
}

///|
test "lenient matrix invalid IAC byte 31 recovers" {
  lenient_assert_invalid_recovers(31)
}

///|
test "lenient matrix invalid IAC byte 42 recovers" {
  lenient_assert_invalid_recovers(42)
}

///|
test "lenient matrix invalid IAC byte 64 recovers" {
  lenient_assert_invalid_recovers(64)
}

///|
test "lenient matrix invalid IAC byte 93 recovers" {
  lenient_assert_invalid_recovers(93)
}

///|
test "lenient matrix invalid IAC byte 127 recovers" {
  lenient_assert_invalid_recovers(127)
}

///|
test "lenient matrix invalid IAC byte 128 recovers" {
  lenient_assert_invalid_recovers(128)
}

///|
test "lenient matrix invalid IAC byte 200 recovers" {
  lenient_assert_invalid_recovers(200)
}

///|
test "lenient matrix invalid IAC byte 239 recovers" {
  lenient_assert_invalid_recovers(239)
}
