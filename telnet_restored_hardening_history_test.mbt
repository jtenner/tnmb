// Restored hostile transcript and encoder hardening cases from deleted scenario fixtures.
// These are production assertions, not fixture self-checks.

///|
fn restored_hardening_config(
  data_cap : Int,
  sb_cap : Int,
) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: data_cap,
    max_subnegotiation_bytes: sb_cap,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
fn restored_assert_command_rejected(command : @telnet.Command) -> Unit raise {
  let out = Bytes::make(8, byte(170))
  match
    @telnet.Encoder::canonical().encode_item(
      @telnet.EncodeItem::Command(command),
      out,
    ) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
      assert_true(e.offset == 0)
      assert_true(e.required_capacity == 0)
      for i = 0; i < out.length(); i = i + 1 {
        assert_true(out[i] == byte(170))
      }
    }
  }
}

///|
test "restored hardening encoder rejects direct IAC command atomically" {
  restored_assert_command_rejected(@telnet.Command::IAC)
}

///|
test "restored hardening encoder rejects direct SB command atomically" {
  restored_assert_command_rejected(@telnet.Command::SB)
}

///|
test "restored hardening encoder rejects direct WILL command atomically" {
  restored_assert_command_rejected(@telnet.Command::WILL)
}

///|
test "restored hardening encoder rejects direct WONT command atomically" {
  restored_assert_command_rejected(@telnet.Command::WONT)
}

///|
test "restored hardening encoder rejects direct DO command atomically" {
  restored_assert_command_rejected(@telnet.Command::DO)
}

///|
test "restored hardening encoder rejects direct DONT command atomically" {
  restored_assert_command_rejected(@telnet.Command::DONT)
}

///|
test "restored hardening negotiation storm parses every command without data amplification" {
  let wire = bytes([
    255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253, 1,
    255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253, 1,
    255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253, 1, 255, 251, 1, 255, 253, 1,
    255, 251, 1, 255, 253, 1,
  ])
  let result = @telnet.Parser::default().feed(wire)
  assert_true(result.bytes_consumed == wire.length())
  assert_true(result.events.length() == 20)
  for i = 0; i < result.events.length(); i = i + 2 {
    assert_true(result.events[i] == neg(@telnet.NegotiationVerb::Will, 1))
    assert_true(result.events[i + 1] == neg(@telnet.NegotiationVerb::Do, 1))
  }
  assert_true(result.parser.checkpoint.mode == @telnet.ParserMode::Normal)
}

///|
test "restored hardening endless subnegotiation reports incomplete on finish" {
  let wire = bytes([
    255, 250, 39, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65,
    65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65,
  ])
  let fed = @telnet.Parser::default().feed(wire)
  assert_true(fed.events == [])
  assert_true(
    fed.parser.checkpoint.mode == @telnet.ParserMode::InSubnegotiation(opt(39)),
  )
  let finished = fed.parser.finish()
  assert_true(finished.complete == false)
  assert_true(
    finished.events ==
    [err(@telnet.TelnetErrorKind::IncompleteSubnegotiation, 34, Some(65))],
  )
}

///|
test "restored hardening oversized endless subnegotiation discards and does not duplicate finish error" {
  let parser = @telnet.Parser::new(restored_hardening_config(4096, 8))
  let fed = parser.feed(
    bytes([255, 250, 39, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65]),
  )
  assert_true(
    fed.events ==
    [err(@telnet.TelnetErrorKind::SubnegotiationTooLarge, 11, Some(65))],
  )
  let finished = fed.parser.finish()
  assert_true(finished.complete == true)
  assert_true(finished.events == [])
}

///|
test "restored hardening alternating invalid IAC bytes all produce precise errors" {
  let wire = [255, 0, 255, 42, 255, 239, 255, 7, 255, 88, 255, 128]
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.bytes_consumed == wire.length())
  assert_true(
    result.events ==
    [
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(0)),
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 3, Some(42)),
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 5, Some(239)),
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 7, Some(7)),
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 9, Some(88)),
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 11, Some(128)),
    ],
  )
}

///|
test "restored hardening refused START_TLS remains a plain negotiation event" {
  let result = @telnet.Parser::default().feed(bytes([255, 252, 46]))
  assert_true(result.events == [neg(@telnet.NegotiationVerb::Wont, 46)])
  assert_true(result.parser.checkpoint.mode == @telnet.ParserMode::Normal)
}
