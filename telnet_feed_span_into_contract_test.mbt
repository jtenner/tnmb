// Public Parser::feed_span_into contract tests.
// These characterize caller-owned event-buffer reuse across parser states.

///|
test "feed_span_into clears stale caller events before emitting" {
  let parser = @telnet.Parser::new(preserve_config())
  let events = [cmd(@telnet.Command::GA), data([90])]
  let first = parser.feed_span_into(span([65, 66]), events)
  assert_true(events_semantically_equal(first.events, [data([65, 66])]))
  assert_true(events_semantically_equal(events, [data([65, 66])]))

  let second = first.parser.feed_span_into(span([255, 241]), events)
  assert_true(second.events == [cmd(@telnet.Command::NOP)])
  assert_true(events == [cmd(@telnet.Command::NOP)])
}

///|
test "feed_span_into reused array matches feed_span across split states" {
  let config = preserve_config()
  let wire = bytes([
    65, // ordinary data
     255, 241, // command split after IAC
     255, 251, 1, // negotiation triplet split before option
     255, 250, 24, 0, 255, 240, // complete subnegotiation split before SE
     66, 255, 255, // escaped IAC data byte
  ])
  let stops = [1, 2, 5, 6, 11, 12, wire.length()]
  let mut plain_parser = @telnet.Parser::new(config)
  let mut into_parser = @telnet.Parser::new(config)
  let reusable_events = [cmd(@telnet.Command::GA)]
  let mut collected : Array[@telnet.Event] = []
  let mut consumed = 0
  let mut start = 0
  for stop in stops {
    let chunk = @telnet.ByteSpan::{ bytes: wire, start, length: stop - start }
    let plain = plain_parser.feed_span(chunk)
    let into = into_parser.feed_span_into(chunk, reusable_events)
    assert_true(into.bytes_consumed == plain.bytes_consumed)
    assert_true(into.parser.checkpoint() == plain.parser.checkpoint())
    assert_true(events_semantically_equal(into.events, plain.events))
    assert_true(events_semantically_equal(reusable_events, plain.events))
    collected = collected + into.events
    consumed = consumed + into.bytes_consumed
    plain_parser = plain.parser
    into_parser = into.parser
    start = stop
  }

  let whole = @telnet.Parser::new(config).feed_span(@telnet.ByteSpan::{
    bytes: wire,
    start: 0,
    length: wire.length(),
  })
  assert_true(consumed == wire.length())
  assert_true(into_parser.checkpoint() == whole.parser.checkpoint())
  assert_true(events_semantically_equal(collected, whole.events))
}

///|
test "feed_span_into completion after incomplete input has no stale events" {
  let parser = @telnet.Parser::new(preserve_config())
  let events = [data([88])]
  let dangling_iac = parser.feed_span_into(span([255]), events)
  assert_true(dangling_iac.bytes_consumed == 1)
  assert_true(dangling_iac.events == [])
  assert_true(events == [])
  assert_true(
    dangling_iac.parser.checkpoint().mode == @telnet.ParserMode::AfterIac,
  )

  events.push(data([89]))
  let completed = dangling_iac.parser.feed_span_into(span([253, 31]), events)
  assert_true(completed.bytes_consumed == 2)
  assert_true(completed.events == [neg(@telnet.NegotiationVerb::Do, 31)])
  assert_true(events == [neg(@telnet.NegotiationVerb::Do, 31)])
  assert_true(completed.parser.checkpoint().mode == @telnet.ParserMode::Normal)
}
