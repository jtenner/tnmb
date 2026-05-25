// Public ByteSpan ownership/borrowing characterization for parser outputs.

///|
fn bytespan_ownership_chunk_config(
  max_data_chunk_bytes : Int,
  cr_policy : @telnet.CrPolicy,
) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes,
    max_subnegotiation_bytes: 8192,
    cr_policy,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
test "no-IAC fast path borrows sliced backing span with nonzero start" {
  let backing = bytes([90, 65, 66, 67, 91])
  let result = @telnet.Parser::default().feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 1,
    length: 3,
  })
  assert_true(result.events.length() == 1)
  match result.events[0] {
    @telnet.Event::Data(d) => {
      assert_true(d.span.bytes == backing)
      assert_true(d.span.bytes.length() == 5)
      assert_true(d.span.start == 1)
      assert_true(d.span.length == 3)
      assert_true(d.span.to_bytes() == bytes([65, 66, 67]))
    }
    _ => assert_true(false)
  }
}

///|
test "chunked no-IAC data events are copied into zero-start spans" {
  let backing = bytes([88, 65, 66, 67, 68, 69, 89])
  let parser = @telnet.Parser::new(
    bytespan_ownership_chunk_config(2, @telnet.CrPolicy::Preserve),
  )
  let result = parser.feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 1,
    length: 5,
  })
  assert_true(result.events.length() == 3)
  match (result.events[0], result.events[1], result.events[2]) {
    (@telnet.Event::Data(a), @telnet.Event::Data(b), @telnet.Event::Data(c)) => {
      assert_true(a.span.start == 0)
      assert_true(a.span.length == 2)
      assert_true(a.span.bytes.length() == 2)
      assert_true(a.span.to_bytes() == bytes([65, 66]))
      assert_true(b.span.start == 0)
      assert_true(b.span.length == 2)
      assert_true(b.span.bytes.length() == 2)
      assert_true(b.span.to_bytes() == bytes([67, 68]))
      assert_true(c.span.start == 0)
      assert_true(c.span.length == 1)
      assert_true(c.span.bytes.length() == 1)
      assert_true(c.span.to_bytes() == bytes([69]))
    }
    _ => assert_true(false)
  }
}

///|
test "data before IAC is copied into a zero-start span" {
  let backing = bytes([88, 65, 66, 255, 241, 89])
  let result = @telnet.Parser::default().feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 1,
    length: 4,
  })
  assert_true(result.events.length() == 2)
  match result.events[0] {
    @telnet.Event::Data(d) => {
      assert_true(d.span.start == 0)
      assert_true(d.span.length == 2)
      assert_true(d.span.bytes.length() == 2)
      assert_true(d.span.to_bytes() == bytes([65, 66]))
    }
    _ => assert_true(false)
  }
  assert_true(result.events[1] == cmd(@telnet.Command::NOP))
}

///|
test "normalized CR output is copied independent of input span shape" {
  let backing = bytes([88, 88, 13, 10, 89])
  let parser = @telnet.Parser::new(
    bytespan_ownership_chunk_config(8192, @telnet.CrPolicy::NormalizeToLf),
  )
  let result = parser.feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 2,
    length: 2,
  })
  assert_true(result.events.length() == 1)
  match result.events[0] {
    @telnet.Event::Data(d) => {
      assert_true(d.span.start == 0)
      assert_true(d.span.length == 1)
      assert_true(d.span.bytes.length() == 1)
      assert_true(d.span.to_bytes() == bytes([10]))
    }
    _ => assert_true(false)
  }
}

///|
test "subnegotiation payload is copied into a zero-start span" {
  let backing = bytes([88, 255, 250, 31, 1, 2, 255, 240, 89])
  let result = @telnet.Parser::default().feed_span(@telnet.ByteSpan::{
    bytes: backing,
    start: 1,
    length: 7,
  })
  assert_true(result.events.length() == 1)
  match result.events[0] {
    @telnet.Event::Subnegotiation(s) => {
      assert_true(s.option == opt(31))
      assert_true(s.payload.start == 0)
      assert_true(s.payload.length == 2)
      assert_true(s.payload.bytes.length() == 2)
      assert_true(s.payload.to_bytes() == bytes([1, 2]))
    }
    _ => assert_true(false)
  }
}
