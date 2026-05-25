// Capacity and atomicity regression tests for encoders. These are test-only
// guardrails for exact-capacity success, short-buffer failure, and sentinel
// preservation.

///|
fn cap_assert_encode_exact_and_short(
  item : @telnet.EncodeItem,
  expected : Array[Int],
) -> Unit raise {
  let encoder = @telnet.Encoder::canonical()
  let required = encoder.required_capacity(item)
  assert_true(required == expected.length())
  let exact = Bytes::make(required, byte(204))
  match encoder.encode_item(item, exact) {
    Ok(r) => {
      assert_true(r.bytes_written == required)
      assert_true(r.required_capacity == required)
      assert_true(exact == bytes(expected))
    }
    Err(_) => assert_true(false)
  }
  if required > 0 {
    let short = Bytes::make(required - 1, byte(173))
    match encoder.encode_item(item, short) {
      Ok(_) => assert_true(false)
      Err(e) => {
        assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
        assert_true(e.required_capacity == required)
        for i = 0; i < short.length(); i = i + 1 {
          assert_true(short[i] == byte(173))
        }
      }
    }
  }
  let padded = Bytes::make(required + 3, byte(90))
  match encoder.encode_item(item, padded) {
    Ok(r) => {
      assert_true(r.bytes_written == required)
      for i = 0; i < expected.length(); i = i + 1 {
        assert_true(padded[i] == byte(expected[i]))
      }
      for i = required; i < padded.length(); i = i + 1 {
        assert_true(padded[i] == byte(90))
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
fn cap_assert_payload_exact_and_short(
  option : Int,
  payload : @telnet.OptionPayload,
  expected : Array[Int],
) -> Unit raise {
  let required = @telnet.OptionPayload::required_capacity(payload)
  assert_true(required == expected.length())
  let exact = Bytes::make(required, byte(204))
  match @telnet.OptionPayload::encode(payload, exact) {
    Ok(r) => {
      assert_true(r.bytes_written == required)
      assert_true(r.required_capacity == required)
      assert_true(exact == bytes(expected))
      match
        @telnet.OptionPayload::decode(opt(option), @telnet.ByteSpan::{
          bytes: exact,
          start: 0,
          length: r.bytes_written,
        }) {
        Ok(_) => ()
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
  if required > 0 {
    let short = Bytes::make(required - 1, byte(173))
    match @telnet.OptionPayload::encode(payload, short) {
      Ok(_) => assert_true(false)
      Err(e) => {
        assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
        assert_true(e.required_capacity == required)
        for i = 0; i < short.length(); i = i + 1 {
          assert_true(short[i] == byte(173))
        }
      }
    }
  }
}

///|
test "capacity encode items exact short and padded buffers" {
  cap_assert_encode_exact_and_short(
    @telnet.EncodeItem::EscapedData(span([65, 255, 66])),
    [65, 255, 255, 66],
  )
  cap_assert_encode_exact_and_short(
    @telnet.EncodeItem::Command(@telnet.Command::NOP),
    [255, 241],
  )
  cap_assert_encode_exact_and_short(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Will, 1)),
    [255, 251, 1],
  )
  cap_assert_encode_exact_and_short(
    @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([0, 255, 0, 24]),
    }),
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
  )
}

///|
test "capacity noncanonical RawData exact and short buffers" {
  let encoder = @telnet.Encoder::new()
  let item = @telnet.EncodeItem::RawData(span([65, 255, 66]))
  assert_true(encoder.required_capacity(item) == 3)
  let exact = Bytes::new(3)
  match encoder.encode_item(item, exact) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(exact == bytes([65, 255, 66]))
    }
    Err(_) => assert_true(false)
  }
  let short = Bytes::make(2, byte(173))
  match encoder.encode_item(item, short) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      assert_true(e.required_capacity == 3)
      assert_true(short == bytes([173, 173]))
    }
  }
}

///|
test "capacity option payload exact and short buffers" {
  cap_assert_payload_exact_and_short(
    24,
    @telnet.OptionPayload::TerminalType(
      @telnet.TerminalTypeMessage::Is("xterm"),
    ),
    [0, 120, 116, 101, 114, 109],
  )
  cap_assert_payload_exact_and_short(
    31,
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (132).to_uint16(),
      rows: (43).to_uint16(),
    }),
    [0, 132, 0, 43],
  )
  cap_assert_payload_exact_and_short(
    46,
    @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows),
    [1],
  )
  cap_assert_payload_exact_and_short(
    42,
    @telnet.OptionPayload::Charset(
      @telnet.CharsetMessage::Request(["UTF-8", "US-ASCII"]),
    ),
    [1, 32, 85, 84, 70, 45, 56, 32, 85, 83, 45, 65, 83, 67, 73, 73],
  )
  cap_assert_payload_exact_and_short(
    34,
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::ForwardMask(
        @telnet.LinemodeForwardMask::Bytes(span([0, 1, 255])),
      ),
    ),
    [2, 0, 1, 255],
  )
}
