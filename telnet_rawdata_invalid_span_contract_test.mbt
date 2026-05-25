// RawData and invalid span contract characterization. These document sharp edges
// without changing production behavior.

///|
test "RawData required_capacity is raw length while canonical encode_item escapes bytes" {
  let item = @telnet.EncodeItem::RawData(span([65, 255, 66]))
  let encoder = @telnet.Encoder::canonical()
  assert_true(encoder.required_capacity(item) == 3)
  let too_small_for_actual = Bytes::make(3, byte(77))
  match encoder.encode_item(item, too_small_for_actual) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      assert_true(e.required_capacity == 4)
      assert_true(too_small_for_actual == bytes([77, 77, 77]))
    }
  }
  let exact_actual = Bytes::new(4)
  match encoder.encode_item(item, exact_actual) {
    Ok(r) => {
      assert_true(r.bytes_written == 4)
      assert_true(exact_actual == bytes([65, 255, 255, 66]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "RawData noncanonical encoder bypasses TELNET escaping" {
  let item = @telnet.EncodeItem::RawData(span([65, 255, 66]))
  let encoder = @telnet.Encoder::new()
  let out = Bytes::new(3)
  match encoder.encode_item(item, out) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(out == bytes([65, 255, 66]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "invalid span safe constructor prevents negative-length parser and encoder access" {
  let clamped = @telnet.ByteSpan::new(bytes([65, 66]), 1, -1)
  assert_true(clamped.is_empty())
  assert_true(@telnet.Parser::default().feed_span(clamped).events == [])
  let out = Bytes::make(1, byte(77))
  match
    @telnet.Encoder::canonical().encode_item(
      @telnet.EncodeItem::EscapedData(clamped),
      out,
    ) {
    Ok(r) => {
      assert_true(r.bytes_written == 0)
      assert_true(out == bytes([77]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "RawData canonical capacity contract matrix for empty and IAC counts" {
  let encoder = @telnet.Encoder::canonical()
  let cases = [
    (span([]), 0, 0),
    (span([65, 66]), 2, 2),
    (span([255]), 1, 2),
    (span([255, 65, 255, 255]), 4, 7),
    (slice([9, 65, 255, 66, 9], 1, 3), 3, 4),
  ]
  cases.each(fn(case) raise {
    let (s, raw_required, actual_required) = case
    let item = @telnet.EncodeItem::RawData(s)
    assert_true(encoder.required_capacity(item) == raw_required)
    let out = Bytes::new(actual_required)
    match encoder.encode_item(item, out) {
      Ok(r) => {
        assert_true(r.bytes_written == actual_required)
        assert_true(r.required_capacity == actual_required)
      }
      Err(_) => assert_true(false)
    }
  })
}

///|
test "RawData padded output preserves bytes beyond canonical write" {
  let encoder = @telnet.Encoder::canonical()
  let out = Bytes::make(8, byte(77))
  match encoder.encode_item(@telnet.EncodeItem::RawData(span([255, 65])), out) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(out == bytes([255, 255, 65, 77, 77, 77, 77, 77]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "RawData short buffers report actual canonical requirement" {
  let encoder = @telnet.Encoder::canonical()
  let item = @telnet.EncodeItem::RawData(span([255, 255, 255]))
  assert_true(encoder.required_capacity(item) == 3)
  for n = 0; n < 6; n = n + 1 {
    let out = Bytes::make(n, byte(77))
    match encoder.encode_item(item, out) {
      Ok(_) => assert_true(false)
      Err(e) => {
        assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
        assert_true(e.required_capacity == 6)
      }
    }
  }
}

///|
test "RawData noncanonical capacity and writes stay raw for sliced spans" {
  let encoder = @telnet.Encoder::new()
  let s = slice([0, 255, 65, 255, 0], 1, 3)
  let item = @telnet.EncodeItem::RawData(s)
  assert_true(encoder.required_capacity(item) == 3)
  let out = Bytes::make(5, byte(99))
  match encoder.encode_item(item, out) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(r.required_capacity == 3)
      assert_true(out == bytes([255, 65, 255, 99, 99]))
    }
    Err(_) => assert_true(false)
  }
}
