// Public raw ByteSpan invalid-span safety characterization. Raw struct fields are
// public, so callers can bypass ByteSpan::new. These tests cover APIs that
// reject such spans without panicking; unsafe call shapes are documented in the
// test plan instead of being executed.

///|
fn raw_invalid_after_end_span() -> @telnet.ByteSpan {
  @telnet.ByteSpan::{ bytes: bytes([65, 66]), start: 3, length: 1 }
}

///|
fn raw_negative_start_span() -> @telnet.ByteSpan {
  @telnet.ByteSpan::{ bytes: bytes([65, 66]), start: -1, length: 1 }
}

///|
fn raw_negative_length_span() -> @telnet.ByteSpan {
  @telnet.ByteSpan::{ bytes: bytes([65, 66]), start: 0, length: -1 }
}

///|
test "invalid raw span encode_data rejects after-end and negative fields" {
  let encoder = @telnet.Encoder::canonical()
  let cases = [
    raw_invalid_after_end_span(),
    raw_negative_start_span(),
    raw_negative_length_span(),
  ]
  cases.each(fn(s) raise {
    let out = Bytes::make(4, byte(77))
    match encoder.encode_data(s, out) {
      Ok(_) => assert_true(false)
      Err(e) => {
        assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
        assert_true(e.required_capacity == 0)
        assert_true(out == bytes([77, 77, 77, 77]))
      }
    }
  })
}

///|
test "invalid raw span EncodeItem EscapedData rejects through encode_item" {
  let out = Bytes::make(4, byte(88))
  match
    @telnet.Encoder::canonical().encode_item(
      @telnet.EncodeItem::EscapedData(raw_invalid_after_end_span()),
      out,
    ) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
      assert_true(out == bytes([88, 88, 88, 88]))
    }
  }
}

///|
test "invalid raw span OptionPayload Raw rejects through encoder" {
  let payload = @telnet.OptionPayload::Raw(
    opt(200),
    raw_invalid_after_end_span(),
  )
  assert_true(@telnet.OptionPayload::required_capacity(payload) == 1)
  let out = Bytes::make(4, byte(99))
  match @telnet.OptionPayload::encode(payload, out) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
      assert_true(out == bytes([99, 99, 99, 99]))
    }
  }
}

///|
test "invalid raw zero-length span is harmless for parser and subnegotiation framing" {
  let s = @telnet.ByteSpan::{ bytes: bytes([65, 66]), start: 99, length: 0 }
  let parsed = @telnet.Parser::default().feed_span(s)
  assert_true(parsed.events == [])
  assert_true(parsed.bytes_consumed == 0)

  let data_out = Bytes::make(1, byte(77))
  match @telnet.Encoder::canonical().encode_data(s, data_out) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
      assert_true(data_out == bytes([77]))
    }
  }

  let sb_out = Bytes::new(5)
  match
    @telnet.Encoder::canonical().encode_subnegotiation(
      @telnet.SubnegotiationEvent::{ option: opt(200), payload: s },
      sb_out,
    ) {
    Ok(r) => {
      assert_true(r.bytes_written == 5)
      assert_true(sb_out == bytes([255, 250, 200, 255, 240]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "invalid raw Linemode ByteSpan can fail safely before payload copy" {
  let payload = @telnet.OptionPayload::Linemode(
    @telnet.LinemodeMessage::ForwardMask(
      @telnet.LinemodeForwardMask::Bytes(raw_invalid_after_end_span()),
    ),
  )
  assert_true(@telnet.OptionPayload::required_capacity(payload) == 2)
  let short_out = Bytes::make(1, byte(77))
  match @telnet.OptionPayload::encode(payload, short_out) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      assert_true(e.required_capacity == 2)
      assert_true(short_out == bytes([77]))
    }
  }
}

///|
test "invalid raw spans can fail safely in length-checked direct codecs" {
  let empty_after_end = @telnet.ByteSpan::{
    bytes: bytes([65, 66]),
    start: 99,
    length: 0,
  }
  match @telnet.TerminalTypeMessage::decode(empty_after_end) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.TelnetErrorKind::IncompleteSubnegotiation)
      assert_true(e.option == Some(opt(24)))
    }
  }
  match @telnet.NawsSize::decode(empty_after_end) {
    Ok(_) => assert_true(false)
    Err(e) =>
      assert_true(e.kind == @telnet.TelnetErrorKind::IncompleteSubnegotiation)
  }
  match @telnet.StartTlsMessage::decode(empty_after_end) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.TelnetErrorKind::PolicyRejected)
      assert_true(e.option == Some(opt(46)))
    }
  }

  let short_after_end = @telnet.ByteSpan::{
    bytes: bytes([65, 66]),
    start: 99,
    length: 1,
  }
  match @telnet.NawsSize::decode(short_after_end) {
    Ok(_) => assert_true(false)
    Err(e) =>
      assert_true(e.kind == @telnet.TelnetErrorKind::IncompleteSubnegotiation)
  }
  match @telnet.OptionPayload::decode(opt(31), short_after_end) {
    Ok(_) => assert_true(false)
    Err(e) =>
      assert_true(e.kind == @telnet.TelnetErrorKind::IncompleteSubnegotiation)
  }
}

///|
test "invalid raw unknown option payload is preserved without indexing" {
  let raw = raw_invalid_after_end_span()
  match @telnet.OptionPayload::decode(opt(200), raw) {
    Ok(payload) =>
      assert_true(payload == @telnet.OptionPayload::Raw(opt(200), raw))
    Err(_) => assert_true(false)
  }
}

///|
test "ByteSpan constructor clamps unsafe ranges for normal API use" {
  let bs = bytes([10, 11, 12])
  let negative_start = @telnet.ByteSpan::new(bs, -5, 2)
  assert_true(negative_start.start == 0)
  assert_true(negative_start.length == 0)

  let overlong = @telnet.ByteSpan::new(bs, 1, 99)
  assert_true(overlong.start == 1)
  assert_true(overlong.length == 2)
  assert_true(overlong.to_bytes() == bytes([11, 12]))

  let negative_length = @telnet.ByteSpan::new(bs, 1, -7)
  assert_true(negative_length.start == 1)
  assert_true(negative_length.length == 0)
}
