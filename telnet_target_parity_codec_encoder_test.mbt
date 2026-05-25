// Target-parity codec and encoder edge-value tests. These intentionally use
// deterministic byte fixtures so wasm/js/native runs assert the same output.

///|
fn target_parity_assert_payload_codec(
  option : Int,
  payload : @telnet.OptionPayload,
  expected : Array[Int],
) -> Unit raise {
  let out = Bytes::new(expected.length())
  match @telnet.OptionPayload::encode(payload, out) {
    Ok(r) => {
      assert_true(r.bytes_written == expected.length())
      assert_true(r.required_capacity == expected.length())
      assert_true(out == bytes(expected))
      match @telnet.OptionPayload::decode(opt(option), span(expected)) {
        Ok(decoded) => assert_true(decoded == payload)
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
fn target_parity_assert_subnegotiation(
  option : Int,
  payload : Array[Int],
  expected_wire : Array[Int],
) -> Unit raise {
  let item = @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
    option: opt(option),
    payload: span(payload),
  })
  let encoder = @telnet.Encoder::canonical()
  assert_true(encoder.required_capacity(item) == expected_wire.length())
  let out = Bytes::new(expected_wire.length())
  match encoder.encode_item(item, out) {
    Ok(r) => {
      assert_true(r.bytes_written == expected_wire.length())
      assert_true(out == bytes(expected_wire))
      let parsed = @telnet.Parser::default().feed(out)
      assert_true(parsed.events == [sb(option, payload)])
    }
    Err(_) => assert_true(false)
  }
}

///|
test "target parity NAWS min max codec and encoder bytes" {
  let cases = [
    (0, 0, [0, 0, 0, 0], [255, 250, 31, 0, 0, 0, 0, 255, 240]),
    (1, 1, [0, 1, 0, 1], [255, 250, 31, 0, 1, 0, 1, 255, 240]),
    (
      255,
      255,
      [0, 255, 0, 255],
      [255, 250, 31, 0, 255, 255, 0, 255, 255, 255, 240],
    ),
    (
      65280,
      65280,
      [255, 0, 255, 0],
      [255, 250, 31, 255, 255, 0, 255, 255, 0, 255, 240],
    ),
    (
      65535,
      65535,
      [255, 255, 255, 255],
      [255, 250, 31, 255, 255, 255, 255, 255, 255, 255, 255, 255, 240],
    ),
  ]
  cases.each(fn(case) raise {
    let (columns, rows, payload_bytes, wire) = case
    let payload = @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: columns.to_uint16(),
      rows: rows.to_uint16(),
    })
    target_parity_assert_payload_codec(31, payload, payload_bytes)
    target_parity_assert_subnegotiation(31, payload_bytes, wire)
  })
}

///|
test "target parity unknown raw high bytes codec and encoder bytes" {
  let payload = [128, 254, 255]
  let decoded = @telnet.OptionPayload::Raw(opt(201), span(payload))
  target_parity_assert_payload_codec(201, decoded, payload)
  target_parity_assert_subnegotiation(201, payload, [
    255, 250, 201, 128, 254, 255, 255, 255, 240,
  ])
}

///|
test "target parity string codec ASCII boundary bytes" {
  let boundary = "\u0000\u001f ~\u007f"
  target_parity_assert_payload_codec(
    24,
    @telnet.OptionPayload::TerminalType(
      @telnet.TerminalTypeMessage::Is(boundary),
    ),
    [0, 0, 31, 32, 126, 127],
  )
  target_parity_assert_payload_codec(
    42,
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::Accepted(boundary)),
    [2, 0, 31, 32, 126, 127],
  )
  target_parity_assert_payload_codec(
    42,
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableIs(boundary)),
    [4, 0, 31, 32, 126, 127],
  )
}

///|
test "target parity large raw Bytes make payloads encode and decode exactly" {
  let large = Bytes::make(8192, byte(128))
  let raw_span = @telnet.ByteSpan::{
    bytes: large,
    start: 0,
    length: large.length(),
  }
  match @telnet.OptionPayload::decode(opt(200), raw_span) {
    Ok(decoded) => {
      assert_true(decoded == @telnet.OptionPayload::Raw(opt(200), raw_span))
      let out = Bytes::new(large.length())
      match @telnet.OptionPayload::encode(decoded, out) {
        Ok(r) => {
          assert_true(r.bytes_written == large.length())
          assert_true(out == large)
        }
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }

  let all_iac = Bytes::make(4096, byte(255))
  let all_iac_span = @telnet.ByteSpan::{
    bytes: all_iac,
    start: 0,
    length: all_iac.length(),
  }
  let item = @telnet.EncodeItem::EscapedData(all_iac_span)
  let encoder = @telnet.Encoder::canonical()
  assert_true(encoder.required_capacity(item) == 8192)
  let escaped = Bytes::new(8192)
  match encoder.encode_item(item, escaped) {
    Ok(r) => {
      assert_true(r.bytes_written == 8192)
      assert_true(escaped == Bytes::make(8192, byte(255)))
      let parsed = @telnet.Parser::default().feed(escaped)
      let mut decoded_len = 0
      parsed.events.each(fn(event) raise {
        match event {
          @telnet.Event::Data(d) => {
            let decoded = d.span.to_bytes()
            decoded_len = decoded_len + decoded.length()
            assert_true(decoded == Bytes::make(decoded.length(), byte(255)))
          }
          _ => assert_true(false)
        }
      })
      assert_true(decoded_len == all_iac.length())
    }
    Err(_) => assert_true(false)
  }
}
