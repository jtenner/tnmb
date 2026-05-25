// Finish/post-finish, ByteSpan boundary, and target-path parity guardrails.

///|
test "finish semantics reset parser and allow fresh feed" {
  let fed = @telnet.Parser::default().feed(bytes([255]))
  let finished = fed.parser.finish()
  assert_true(finished.complete == false)
  assert_true(
    finished.events ==
    [err(@telnet.TelnetErrorKind::IncompleteIac, 0, Some(255))],
  )
  assert_true(finished.parser.checkpoint.mode == @telnet.ParserMode::Normal)
  let fresh = finished.parser.feed(bytes([65, 66]))
  assert_true(fresh.events == [data([65, 66])])
}

///|
test "finish complete parser remains reusable and idempotent after reset" {
  let finished = @telnet.Parser::default().feed(bytes([65])).parser.finish()
  assert_true(finished.complete == true)
  assert_true(finished.events == [])
  let again = finished.parser.finish()
  assert_true(again.complete == true)
  assert_true(again.events == [])
}

///|
test "ByteSpan::new invalid bounds clamp before parser feed_span" {
  let input = bytes([65, 66, 67])
  let bad_start = @telnet.ByteSpan::new(input, -1, 2)
  assert_true(bad_start.is_empty())
  assert_true(@telnet.Parser::default().feed_span(bad_start).events == [])
  let bad_length = @telnet.ByteSpan::new(input, 1, -1)
  assert_true(bad_length.is_empty())
  assert_true(@telnet.Parser::default().feed_span(bad_length).events == [])
  let too_long = @telnet.ByteSpan::new(input, 2, 4)
  assert_true(too_long.start == 2)
  assert_true(too_long.length == 1)
  let parsed = @telnet.Parser::default().feed_span(too_long)
  match parsed.events[0] {
    @telnet.Event::Data(d) => assert_true(d.span.to_bytes() == bytes([67]))
    _ => assert_true(false)
  }
}

///|
test "parser feed_span sliced input preserves exact source window" {
  let input = bytes([90, 65, 255, 241, 66, 91])
  let result = @telnet.Parser::default().feed_span(@telnet.ByteSpan::{
    bytes: input,
    start: 1,
    length: 4,
  })
  assert_true(
    result.events == [data([65]), cmd(@telnet.Command::NOP), data([66])],
  )
  assert_true(result.bytes_consumed == 4)
}

///|
test "zero copy fast path borrows original no-IAC input bytes" {
  let input = bytes([65, 66, 67])
  let result = @telnet.Parser::default().feed(input)
  match result.events[0] {
    @telnet.Event::Data(d) => {
      assert_true(d.span.bytes == input)
      assert_true(d.span.start == 0)
      assert_true(d.span.length == 3)
    }
    _ => assert_true(false)
  }
}

///|
test "target parity guard large no-IAC scan chunks identically" {
  let arr = Array::make(10000, 65)
  let wire = Bytes::from_array(arr.map(fn(n) { byte(n) }))
  let result = @telnet.Parser::default().feed(wire)
  assert_true(result.events.length() == 2)
  match (result.events[0], result.events[1]) {
    (@telnet.Event::Data(a), @telnet.Event::Data(b)) => {
      assert_true(a.span.length == 8192)
      assert_true(b.span.length == 1808)
    }
    _ => assert_true(false)
  }
}

///|
test "target parity guard subnegotiation scan handles large escaped payload" {
  let payload = Array::new()
  for i = 0; i < 2048; i = i + 1 {
    payload.push(65)
  }
  payload.push(255)
  payload.push(255)
  payload.push(66)
  let wire = [255, 250, 50] + payload + [255, 240]
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.events.length() == 1)
  match result.events[0] {
    @telnet.Event::Subnegotiation(s) => {
      assert_true(s.option == opt(50))
      assert_true(s.payload.length == 2050)
      assert_true(s.payload.bytes[s.payload.start + 2048] == byte(255))
      assert_true(s.payload.bytes[s.payload.start + 2049] == byte(66))
    }
    _ => assert_true(false)
  }
}
