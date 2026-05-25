// Scanner stress tests intended to exercise both JS fallback and native C helper
// paths through public parser APIs.

///|
fn scanner_expected_chunks(n : Int) -> Int {
  if n == 0 {
    0
  } else {
    (n + 8191) / 8192
  }
}

///|
test "scanner stress no IAC across multiple capacity chunks" {
  let arr = Array::make(25000, 65)
  let wire = Bytes::from_array(arr.map(fn(n) { byte(n) }))
  let result = @telnet.Parser::default().feed(wire)
  assert_true(result.events.length() == 4)
  let lengths = Array::new()
  result.events.each(fn(event) raise {
    match event {
      @telnet.Event::Data(d) => lengths.push(d.span.length)
      _ => assert_true(false)
    }
  })
  assert_true(lengths == [8192, 8192, 8192, 424])
}

///|
test "scanner stress no-IAC exact boundary sizes" {
  [0, 1, 8191, 8192, 8193, 65535].each(fn(size) raise {
    let wire = Bytes::from_array(Array::make(size, byte(65)))
    let r = @telnet.Parser::default().feed(wire)
    assert_true(r.bytes_consumed == size)
    assert_true(r.events.length() == scanner_expected_chunks(size))
    if size > 0 {
      match r.events[0] {
        @telnet.Event::Data(d) => assert_true(d.span.to_bytes().length() > 0)
        _ => assert_true(false)
      }
    }
  })
}

///|
test "scanner stress IAC at chunk boundary after long data" {
  let data_prefix = Array::make(8192, 65)
  let wire = data_prefix + [255, 241, 66]
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.events.length() == 3)
  match result.events[0] {
    @telnet.Event::Data(d) => assert_true(d.span.length == 8192)
    _ => assert_true(false)
  }
  assert_true(result.events[1] == cmd(@telnet.Command::NOP))
  assert_true(result.events[2] == data([66]))
}

///|
test "scanner stress IAC at start middle and end of large buffers" {
  let positions = [0, 4096, 8192]
  positions.each(fn(pos) raise {
    let suffix = 8192 - pos
    let wire = Array::make(pos, 65) + [255, 241] + Array::make(suffix, 66)
    let r = @telnet.Parser::default().feed(bytes(wire))
    assert_true(r.bytes_consumed == wire.length())
    assert_true(guardrail_count_kind(r.events, "command") == 1)
    assert_true(r.parser.finish().events == [])
  })
  let dangling = @telnet.Parser::default().feed(
    Bytes::from_array(Array::make(8192, byte(65)) + [byte(255)]),
  )
  assert_true(dangling.bytes_consumed == 8193)
  let finish = dangling.parser.finish()
  assert_true(
    finish.events ==
    [err(@telnet.TelnetErrorKind::IncompleteIac, 8192, Some(255))],
  )
}

///|
test "scanner stress feed_span nonzero start large no-IAC slice" {
  let backing = Bytes::from_array(
    [byte(9)] + Array::make(9000, byte(65)) + [byte(9)],
  )
  let r = @telnet.Parser::default().feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 1,
    length: 9000,
  })
  assert_true(r.bytes_consumed == 9000)
  assert_true(r.events.length() == 2)
  match r.events[0] {
    @telnet.Event::Data(d) => {
      assert_true(d.span.length == 8192)
      assert_true(d.span.bytes[d.span.start] == byte(65))
    }
    _ => assert_true(false)
  }
  match r.events[1] {
    @telnet.Event::Data(d) => assert_true(d.span.length == 808)
    _ => assert_true(false)
  }
}

///|
test "scanner stress feed_span nonzero start reaches backing end" {
  let backing = Bytes::from_array([byte(7)] + Array::make(10000, byte(65)))
  let span = @telnet.ByteSpan::{
    bytes: backing,
    start: 1,
    length: backing.length() - 1,
  }
  let r = @telnet.Parser::default().feed_span(span)
  assert_true(span.start + span.length == backing.length())
  assert_true(r.bytes_consumed == 10000)
  assert_true(r.events.length() == 2)
  match r.events[0] {
    @telnet.Event::Data(d) => {
      assert_true(d.span.start == 0)
      assert_true(d.span.length == 8192)
      assert_true(d.span.to_bytes().length() == 8192)
      assert_true(d.span.bytes[d.span.start] == byte(65))
    }
    _ => assert_true(false)
  }
  match r.events[1] {
    @telnet.Event::Data(d) => {
      assert_true(d.span.length == 1808)
      assert_true(d.span.bytes[d.span.start + d.span.length - 1] == byte(65))
    }
    _ => assert_true(false)
  }
}

///|
test "scanner stress feed_span IAC immediately after nonzero start" {
  let backing = Bytes::from_array(
    [byte(7), byte(255), byte(241)] + Array::make(9000, byte(66)),
  )
  let r = @telnet.Parser::default().feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 1,
    length: backing.length() - 1,
  })
  assert_true(r.bytes_consumed == backing.length() - 1)
  assert_true(r.events.length() == 3)
  assert_true(r.events[0] == cmd(@telnet.Command::NOP))
  match r.events[1] {
    @telnet.Event::Data(d) => assert_true(d.span.length == 8192)
    _ => assert_true(false)
  }
  match r.events[2] {
    @telnet.Event::Data(d) => assert_true(d.span.length == 808)
    _ => assert_true(false)
  }
}

///|
test "scanner stress feed_span IAC final byte after nonzero start" {
  let backing = Bytes::from_array(
    [byte(7)] + Array::make(9000, byte(65)) + [byte(255)],
  )
  let r = @telnet.Parser::default().feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 1,
    length: backing.length() - 1,
  })
  assert_true(r.bytes_consumed == backing.length() - 1)
  assert_true(r.events.length() == 2)
  match r.events[0] {
    @telnet.Event::Data(d) => assert_true(d.span.length == 8192)
    _ => assert_true(false)
  }
  match r.events[1] {
    @telnet.Event::Data(d) => assert_true(d.span.length == 808)
    _ => assert_true(false)
  }
  let finish = r.parser.finish()
  assert_true(
    finish.events ==
    [err(@telnet.TelnetErrorKind::IncompleteIac, 9000, Some(255))],
  )
}

///|
test "scanner stress repeated adjacent feed_span slices from same backing" {
  let backing = Bytes::from_array(
    [byte(9)] +
    Array::make(6000, byte(65)) +
    Array::make(6000, byte(66)) +
    [byte(255), byte(241)],
  )
  let first = @telnet.Parser::default().feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 1,
    length: 6000,
  })
  assert_true(first.bytes_consumed == 6000)
  assert_true(first.events.length() == 1)
  match first.events[0] {
    @telnet.Event::Data(d) => {
      assert_true(d.span.start == 1)
      assert_true(d.span.length == 6000)
      assert_true(d.span.bytes[d.span.start] == byte(65))
    }
    _ => assert_true(false)
  }
  let second = first.parser.feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 6001,
    length: 6000,
  })
  assert_true(second.bytes_consumed == 6000)
  assert_true(second.events.length() == 1)
  match second.events[0] {
    @telnet.Event::Data(d) => {
      assert_true(d.span.start == 6001)
      assert_true(d.span.length == 6000)
      assert_true(d.span.bytes[d.span.start] == byte(66))
    }
    _ => assert_true(false)
  }
  let third = second.parser.feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 12001,
    length: 2,
  })
  assert_true(third.events == [cmd(@telnet.Command::NOP)])
  assert_true(third.parser.finish().events == [])
}

///|
test "scanner stress large no-IAC feed followed by IAC command feed" {
  let data_feed = Bytes::from_array(Array::make(12000, byte(65)))
  let first = @telnet.Parser::default().feed(data_feed)
  assert_true(first.bytes_consumed == 12000)
  assert_true(first.events.length() == 2)
  match first.events[0] {
    @telnet.Event::Data(d) => assert_true(d.span.length == 8192)
    _ => assert_true(false)
  }
  match first.events[1] {
    @telnet.Event::Data(d) => assert_true(d.span.length == 3808)
    _ => assert_true(false)
  }
  let second = first.parser.feed(bytes([255, 241, 67]))
  assert_true(second.events.length() == 2)
  assert_true(second.events[0] == cmd(@telnet.Command::NOP))
  assert_true(second.events[1] == data([67]))
}

///|
test "scanner stress dense IAC escaped data run" {
  let wire = Array::new()
  for i = 0; i < 2048; i = i + 1 {
    ignore(i)
    wire.push(255)
    wire.push(255)
  }
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.events.length() == 2048)
  result.events.each(fn(event) raise { assert_true(event == data([255])) })
}

///|
test "scanner stress subnegotiation long payload with terminal IAC SE" {
  let payload = Array::make(6000, 65)
  let wire = [255, 250, 50] + payload + [255, 240]
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.events.length() == 1)
  match result.events[0] {
    @telnet.Event::Subnegotiation(s) => {
      assert_true(s.option == opt(50))
      assert_true(s.payload.length == 6000)
      assert_true(s.payload.bytes[s.payload.start] == byte(65))
      assert_true(s.payload.bytes[s.payload.start + 5999] == byte(65))
    }
    _ => assert_true(false)
  }
}

///|
test "scanner stress subnegotiation long payload with escaped IAC near end" {
  let payload = Array::make(4096, 65)
  let wire = [255, 250, 50] + payload + [255, 255, 66, 255, 240]
  let result = @telnet.Parser::default().feed(bytes(wire))
  match result.events[0] {
    @telnet.Event::Subnegotiation(s) => {
      assert_true(s.payload.length == 4098)
      assert_true(s.payload.bytes[s.payload.start + 4096] == byte(255))
      assert_true(s.payload.bytes[s.payload.start + 4097] == byte(66))
    }
    _ => assert_true(false)
  }
}

///|
test "scanner stress subnegotiation escaped IAC around capacity boundary" {
  let payload = Array::make(8190, 65)
  let wire = [255, 250, 50] + payload + [255, 255, 66, 255, 240]
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.bytes_consumed == wire.length())
  assert_true(result.events.length() == 1)
  match result.events[0] {
    @telnet.Event::Subnegotiation(s) => {
      assert_true(s.payload.length == 8192)
      assert_true(s.payload.bytes[s.payload.start + 8190] == byte(255))
      assert_true(s.payload.bytes[s.payload.start + 8191] == byte(66))
    }
    _ => assert_true(false)
  }
}
