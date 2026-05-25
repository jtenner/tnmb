// Encoder edge matrices for raw-data mode, invalid spans, assume-capacity
// methods, and verb/command helper relationships.

///|
fn encoder_edge_invalid_span() -> @telnet.ByteSpan {
  @telnet.ByteSpan::{ bytes: bytes([65, 66]), start: 9, length: 1 }
}

///|
test "encoder edge canonical RawData currently escapes like EscapedData" {
  let item = @telnet.EncodeItem::RawData(span([65, 255, 66]))
  let out = Bytes::new(4)
  let encoder = @telnet.Encoder::canonical()
  assert_true(encoder.required_capacity(item) == 3)
  match encoder.encode_item(item, out) {
    Ok(r) => {
      assert_true(r.bytes_written == 4)
      assert_true(r.required_capacity == 4)
      assert_true(out == bytes([65, 255, 255, 66]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "encoder edge invalid spans reject without touching output" {
  let encoder = @telnet.Encoder::canonical()
  let out = Bytes::make(4, byte(77))
  match
    encoder.encode_item(
      @telnet.EncodeItem::EscapedData(encoder_edge_invalid_span()),
      out,
    ) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::UnsupportedEncoding)
      assert_true(out == bytes([77, 77, 77, 77]))
    }
  }
}

///|
test "encoder edge assume-capacity rejects negative required and short output" {
  let encoder = @telnet.Encoder::canonical()
  let out = Bytes::make(2, byte(77))
  match encoder.encode_data_assume_capacity(span([65]), out, -1) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      assert_true(e.required_capacity == -1)
      assert_true(out == bytes([77, 77]))
    }
  }
  match
    encoder.encode_subnegotiation_assume_capacity(
      @telnet.SubnegotiationEvent::{ option: opt(24), payload: span([1]) },
      out,
      6,
    ) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      assert_true(e.required_capacity == 6)
      assert_true(out == bytes([77, 77]))
    }
  }
}

///|
test "encoder edge assume-capacity short output uses caller required value" {
  let encoder = @telnet.Encoder::canonical()

  let data_out = Bytes::make(3, byte(70))
  match encoder.encode_data_assume_capacity(span([65]), data_out, 4) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      assert_true(e.required_capacity == 4)
      assert_true(data_out == bytes([70, 70, 70]))
    }
  }

  let sb_out = Bytes::make(5, byte(71))
  match
    encoder.encode_subnegotiation_assume_capacity(
      @telnet.SubnegotiationEvent::{ option: opt(31), payload: span([]) },
      sb_out,
      6,
    ) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      assert_true(e.required_capacity == 6)
      assert_true(sb_out == bytes([71, 71, 71, 71, 71]))
    }
  }
}

///|
test "encoder edge assume-capacity wrong required values characterize output" {
  let canonical = @telnet.Encoder::canonical()
  let raw = @telnet.Encoder::new()

  let plain_larger = Bytes::make(5, byte(90))
  match
    canonical.encode_data_assume_capacity(span([65, 66, 67]), plain_larger, 5) {
    Ok(r) => {
      assert_true(r.bytes_written == 5)
      assert_true(r.required_capacity == 5)
      assert_true(plain_larger == bytes([65, 66, 67, 90, 90]))
    }
    Err(_) => assert_true(false)
  }

  let escaped_smaller = Bytes::make(6, byte(91))
  match
    canonical.encode_data_assume_capacity(
      span([65, 255, 66]),
      escaped_smaller,
      2,
    ) {
    Ok(r) => {
      assert_true(r.bytes_written == 2)
      assert_true(r.required_capacity == 2)
      assert_true(escaped_smaller == bytes([65, 255, 255, 66, 91, 91]))
    }
    Err(_) => assert_true(false)
  }

  let escaped_larger = Bytes::make(6, byte(92))
  match
    canonical.encode_data_assume_capacity(span([255, 65]), escaped_larger, 6) {
    Ok(r) => {
      assert_true(r.bytes_written == 6)
      assert_true(r.required_capacity == 6)
      assert_true(escaped_larger == bytes([255, 255, 65, 92, 92, 92]))
    }
    Err(_) => assert_true(false)
  }

  let raw_smaller = Bytes::make(5, byte(93))
  match raw.encode_data_assume_capacity(span([65, 255, 66]), raw_smaller, 1) {
    Ok(r) => {
      assert_true(r.bytes_written == 1)
      assert_true(r.required_capacity == 1)
      assert_true(raw_smaller == bytes([65, 255, 66, 93, 93]))
    }
    Err(_) => assert_true(false)
  }

  let raw_larger = Bytes::make(5, byte(94))
  match raw.encode_data_assume_capacity(span([65, 255, 66]), raw_larger, 5) {
    Ok(r) => {
      assert_true(r.bytes_written == 5)
      assert_true(r.required_capacity == 5)
      assert_true(raw_larger == bytes([65, 255, 66, 94, 94]))
    }
    Err(_) => assert_true(false)
  }

  let empty_data_nonzero = Bytes::make(3, byte(95))
  match canonical.encode_data_assume_capacity(span([]), empty_data_nonzero, 3) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(r.required_capacity == 3)
      assert_true(empty_data_nonzero == bytes([95, 95, 95]))
    }
    Err(_) => assert_true(false)
  }

  let sb_event = @telnet.SubnegotiationEvent::{
    option: opt(24),
    payload: span([1, 255, 2]),
  }
  let sb_smaller = Bytes::make(10, byte(96))
  match
    canonical.encode_subnegotiation_assume_capacity(sb_event, sb_smaller, 4) {
    Ok(r) => {
      assert_true(r.bytes_written == 4)
      assert_true(r.required_capacity == 4)
      assert_true(
        sb_smaller == bytes([255, 250, 24, 1, 255, 255, 2, 255, 240, 96]),
      )
    }
    Err(_) => assert_true(false)
  }

  let sb_larger = Bytes::make(11, byte(97))
  match
    canonical.encode_subnegotiation_assume_capacity(sb_event, sb_larger, 11) {
    Ok(r) => {
      assert_true(r.bytes_written == 11)
      assert_true(r.required_capacity == 11)
      assert_true(
        sb_larger == bytes([255, 250, 24, 1, 255, 255, 2, 255, 240, 97, 97]),
      )
    }
    Err(_) => assert_true(false)
  }

  let empty_sb = Bytes::make(7, byte(98))
  match
    canonical.encode_subnegotiation_assume_capacity(
      @telnet.SubnegotiationEvent::{ option: opt(24), payload: span([]) },
      empty_sb,
      7,
    ) {
    Ok(r) => {
      assert_true(r.bytes_written == 7)
      assert_true(r.required_capacity == 7)
      assert_true(empty_sb == bytes([255, 250, 24, 255, 240, 98, 98]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "encoder edge negotiation verb command helper matrix" {
  assert_true(
    @telnet.NegotiationVerb::Will.to_command() == @telnet.Command::WILL,
  )
  assert_true(
    @telnet.NegotiationVerb::from_command(@telnet.Command::WILL) ==
    Some(@telnet.NegotiationVerb::Will),
  )
  assert_true(
    @telnet.NegotiationVerb::Wont.to_command() == @telnet.Command::WONT,
  )
  assert_true(
    @telnet.NegotiationVerb::from_command(@telnet.Command::WONT) ==
    Some(@telnet.NegotiationVerb::Wont),
  )
  assert_true(@telnet.NegotiationVerb::Do.to_command() == @telnet.Command::DO)
  assert_true(
    @telnet.NegotiationVerb::from_command(@telnet.Command::DO) ==
    Some(@telnet.NegotiationVerb::Do),
  )
  assert_true(
    @telnet.NegotiationVerb::Dont.to_command() == @telnet.Command::DONT,
  )
  assert_true(
    @telnet.NegotiationVerb::from_command(@telnet.Command::DONT) ==
    Some(@telnet.NegotiationVerb::Dont),
  )
  assert_true(
    @telnet.NegotiationVerb::from_command(@telnet.Command::SE) == None,
  )
  assert_true(
    @telnet.NegotiationVerb::from_command(@telnet.Command::NOP) == None,
  )
  assert_true(
    @telnet.NegotiationVerb::from_command(@telnet.Command::SB) == None,
  )
  assert_true(
    @telnet.NegotiationVerb::from_command(@telnet.Command::IAC) == None,
  )
}
