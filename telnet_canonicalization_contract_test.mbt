// Canonicalization contracts: decode accepts some noncanonical wire forms while
// encoders produce stable canonical payload bytes.

///|
test "canonicalization CHARSET arbitrary separator decodes then re-encodes with space" {
  match
    @telnet.OptionPayload::decode(
      opt(42),
      span([1, 59, 85, 84, 70, 45, 56, 59, 85, 83, 45, 65, 83, 67, 73, 73]),
    ) {
    Ok(payload) => {
      assert_true(
        payload ==
        @telnet.OptionPayload::Charset(
          @telnet.CharsetMessage::Request(["UTF-8", "US-ASCII"]),
        ),
      )
      let out = Bytes::new(@telnet.OptionPayload::required_capacity(payload))
      match @telnet.OptionPayload::encode(payload, out) {
        Ok(_) =>
          assert_true(
            out ==
            bytes([
              1, 32, 85, 84, 70, 45, 56, 32, 85, 83, 45, 65, 83, 67, 73, 73,
            ]),
          )
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
test "canonicalization LINEMODE flag order encodes to bit mask independent of source order" {
  let a = @telnet.OptionPayload::Linemode(
    @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
      flags: [@telnet.LinemodeModeFlag::Edit, @telnet.LinemodeModeFlag::TrapSig],
    }),
  )
  let b = @telnet.OptionPayload::Linemode(
    @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
      flags: [@telnet.LinemodeModeFlag::TrapSig, @telnet.LinemodeModeFlag::Edit],
    }),
  )
  let out_a = Bytes::new(2)
  let out_b = Bytes::new(2)
  ignore(@telnet.OptionPayload::encode(a, out_a))
  ignore(@telnet.OptionPayload::encode(b, out_b))
  assert_true(out_a == bytes([1, 3]))
  assert_true(out_b == bytes([1, 3]))
}

///|
test "canonicalization Raw option payload encodes payload bytes without TELNET escaping" {
  let payload = @telnet.OptionPayload::Raw(opt(93), span([65, 255, 66]))
  let out = Bytes::new(@telnet.OptionPayload::required_capacity(payload))
  match @telnet.OptionPayload::encode(payload, out) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(out == bytes([65, 255, 66]))
    }
    Err(_) => assert_true(false)
  }
}
