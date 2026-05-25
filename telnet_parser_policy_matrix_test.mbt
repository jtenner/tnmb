// Parser policy matrices for CR handling, coalescing, capacity, and checkpoint
// transitions that are easy to regress when optimizing scanner paths.

///|
fn parser_policy_config(
  cr : @telnet.CrPolicy,
  coalescing : @telnet.DataCoalescing,
  data_cap : Int,
  sb_cap : Int,
) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: data_cap,
    max_subnegotiation_bytes: sb_cap,
    cr_policy: cr,
    data_coalescing: coalescing,
    strict_commands: true,
  }
}

///|
fn parser_policy_events_all_splits(
  config : @telnet.ParserConfig,
  wire : Array[Int],
  expected : Array[@telnet.Event],
) -> Unit raise {
  for split = 0; split <= wire.length(); split = split + 1 {
    assert_true(
      events_semantically_equal(tdd_feed_split(config, wire, split), expected),
    )
  }
}

///|
test "parser policy validate CR split matrix" {
  let config = parser_policy_config(
    @telnet.CrPolicy::ValidateNvt,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    4096,
    8192,
  )
  parser_policy_events_all_splits(config, [13, 10], [data([13, 10])])
  parser_policy_events_all_splits(config, [13, 0], [data([13, 0])])
  parser_policy_events_all_splits(config, [13, 88], [
    err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(88)),
    data([88]),
  ])
  let fed = @telnet.Parser::new(config).feed(bytes([13]))
  assert_true(fed.events == [])
  assert_true(
    fed.parser.finish().events ==
    [err(@telnet.TelnetErrorKind::PolicyRejected, 0, Some(13))],
  )
}

///|
test "parser policy normalize CR split matrix" {
  let config = parser_policy_config(
    @telnet.CrPolicy::NormalizeToLf,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    4096,
    8192,
  )
  parser_policy_events_all_splits(config, [13, 10], [data([10])])
  parser_policy_events_all_splits(config, [13, 0], [data([13])])
  parser_policy_events_all_splits(config, [13, 88], [data([13, 88])])
  let fed = @telnet.Parser::new(config).feed(bytes([13]))
  assert_true(fed.events == [])
  assert_true(
    fed.parser.finish().events ==
    [err(@telnet.TelnetErrorKind::PolicyRejected, 0, Some(13))],
  )
}

///|
test "parser policy preserve CR never delays or rewrites bytes" {
  let config = parser_policy_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    4096,
    8192,
  )
  assert_true(
    @telnet.Parser::new(config).feed(bytes([13])).events == [data([13])],
  )
  assert_true(
    @telnet.Parser::new(config).feed(bytes([13, 10])).events == [data([13, 10])],
  )
  assert_true(
    @telnet.Parser::new(config).feed(bytes([13, 0])).events == [data([13, 0])],
  )
  assert_true(
    @telnet.Parser::new(config).feed(bytes([13, 88])).events == [data([13, 88])],
  )
}

///|
test "parser policy zero data capacity rejects every data byte and recovers commands" {
  let config = parser_policy_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    0,
    8192,
  )
  let result = @telnet.Parser::new(config).feed(bytes([65, 66, 255, 241, 67]))
  assert_true(
    result.events ==
    [
      err(@telnet.TelnetErrorKind::PolicyRejected, 0, Some(65)),
      err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(66)),
      cmd(@telnet.Command::NOP),
      err(@telnet.TelnetErrorKind::PolicyRejected, 4, Some(67)),
    ],
  )
}

///|
test "parser policy coalescing capacity splits preserved fast path predictably" {
  let config = parser_policy_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCapacity,
    3,
    8192,
  )
  let result = @telnet.Parser::new(config).feed(
    bytes([65, 66, 67, 68, 69, 70, 71]),
  )
  assert_true(
    result.events == [data([65, 66, 67]), data([68, 69, 70]), data([71])],
  )
}

///|
test "parser policy checkpoint modes cover partial command families" {
  let parser = @telnet.Parser::default()
  assert_true(
    parser.feed(bytes([255])).parser.checkpoint.mode ==
    @telnet.ParserMode::AfterIac,
  )
  assert_true(
    parser.feed(bytes([255, 251])).parser.checkpoint.mode ==
    @telnet.ParserMode::AfterNegotiationVerb(@telnet.NegotiationVerb::Will),
  )
  assert_true(
    parser.feed(bytes([255, 252])).parser.checkpoint.mode ==
    @telnet.ParserMode::AfterNegotiationVerb(@telnet.NegotiationVerb::Wont),
  )
  assert_true(
    parser.feed(bytes([255, 253])).parser.checkpoint.mode ==
    @telnet.ParserMode::AfterNegotiationVerb(@telnet.NegotiationVerb::Do),
  )
  assert_true(
    parser.feed(bytes([255, 254])).parser.checkpoint.mode ==
    @telnet.ParserMode::AfterNegotiationVerb(@telnet.NegotiationVerb::Dont),
  )
  assert_true(
    parser.feed(bytes([255, 250])).parser.checkpoint.mode ==
    @telnet.ParserMode::AfterSubnegotiationStart,
  )
  assert_true(
    parser.feed(bytes([255, 250, 24])).parser.checkpoint.mode ==
    @telnet.ParserMode::InSubnegotiation(opt(24)),
  )
  assert_true(
    parser.feed(bytes([255, 250, 24, 1, 255])).parser.checkpoint.mode ==
    @telnet.ParserMode::InSubnegotiationAfterIac(opt(24)),
  )
}
