// Unknown/private option raw payload preservation matrix.

///|
fn raw_payload_assert(option : Int, payload : Array[Int]) -> Unit raise {
  match @telnet.OptionPayload::decode(opt(option), span(payload)) {
    Ok(decoded) => {
      assert_true(
        decoded == @telnet.OptionPayload::Raw(opt(option), span(payload)),
      )
      let out = Bytes::new(@telnet.OptionPayload::required_capacity(decoded))
      match @telnet.OptionPayload::encode(decoded, out) {
        Ok(r) => {
          assert_true(r.bytes_written == payload.length())
          assert_true(out == bytes(payload))
        }
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
test "unknown raw payload matrix preserves empty payloads" {
  [50, 51, 70, 86, 93, 138, 139, 140, 141, 200, 201, 254].each(fn(
    option,
  ) raise {
    raw_payload_assert(option, [])
  })
}

///|
test "unknown raw payload matrix preserves high bytes and IAC bytes" {
  let payloads = [
    [0],
    [65, 66, 67],
    [255],
    [0, 128, 255, 254],
    [1, 255, 240, 2],
  ]
  [50, 86, 93, 138, 140, 200, 201, 254].each(fn(option) raise {
    payloads.each(fn(payload) raise { raw_payload_assert(option, payload) })
  })
}

///|
test "unknown raw subnegotiation parser and codec agree for private options" {
  [86, 93, 201].each(fn(option) raise {
    let wire = [255, 250, option, 1, 255, 255, 2, 255, 240]
    let parsed = @telnet.Parser::default().feed(bytes(wire))
    assert_true(parsed.events == [sb(option, [1, 255, 2])])
    raw_payload_assert(option, [1, 255, 2])
  })
}
