// Parser::restore semantics tests. These characterize exactly what checkpoint
// metadata can resume today, including where buffered bytes are intentionally not restored.

///|
fn restore_config() -> @telnet.ParserConfig {
  @telnet.Parser::default_config()
}

///|
test "restore after IAC resumes command parsing" {
  let first = @telnet.Parser::default().feed(bytes([255]))
  let restored = @telnet.Parser::restore(
    restore_config(),
    first.parser.checkpoint(),
  )
  let second = restored.feed(bytes([241]))
  assert_true(second.events == [cmd(@telnet.Command::NOP)])
}

///|
test "restore after negotiation verb resumes option parsing" {
  let first = @telnet.Parser::default().feed(bytes([255, 251]))
  let restored = @telnet.Parser::restore(
    restore_config(),
    first.parser.checkpoint(),
  )
  let second = restored.feed(bytes([1]))
  assert_true(second.events == [neg(@telnet.NegotiationVerb::Will, 1)])
}

///|
test "restore after subnegotiation start resumes option then payload" {
  let first = @telnet.Parser::default().feed(bytes([255, 250]))
  let restored = @telnet.Parser::restore(
    restore_config(),
    first.parser.checkpoint(),
  )
  let second = restored.feed(bytes([24, 1, 255, 240]))
  assert_true(second.events == [sb(24, [1])])
}

///|
test "restore in subnegotiation resumes mode but not buffered payload" {
  let first = @telnet.Parser::default().feed(bytes([255, 250, 24, 65]))
  assert_true(first.parser.checkpoint().buffered_subnegotiation_length == 1)
  let restored = @telnet.Parser::restore(
    restore_config(),
    first.parser.checkpoint(),
  )
  let second = restored.feed(bytes([66, 255, 240]))
  assert_true(second.events == [sb(24, [66])])
}

///|
test "restore after pending CR preserves checkpoint offset but not pending CR buffer" {
  let config = @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::ValidateNvt,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
  let first = @telnet.Parser::new(config).feed(bytes([13]))
  assert_true(first.parser.checkpoint().buffered_data_length == 1)
  let restored = @telnet.Parser::restore(config, first.parser.checkpoint())
  let second = restored.feed(bytes([10]))
  assert_true(second.events == [data([10])])
}
