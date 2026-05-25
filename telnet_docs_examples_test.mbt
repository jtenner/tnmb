// User-facing API example tests. Keep these close to README-style snippets so
// documentation examples stay executable.

///|
test "docs example parse a banner and AYT command" {
  let parser = @telnet.Parser::default()
  let result = parser.feed(bytes([72, 105, 255, 246]))
  assert_true(result.events == [data([72, 105]), cmd(@telnet.Command::AYT)])
}

///|
test "docs example encode WILL ECHO" {
  let out = Bytes::new(3)
  match
    @telnet.Encoder::canonical().encode_item(
      @telnet.EncodeItem::Negotiation(
        neg_event(@telnet.NegotiationVerb::Will, 1),
      ),
      out,
    ) {
    Ok(r) => {
      assert_true(r.bytes_written == 3)
      assert_true(out == bytes([255, 251, 1]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "docs example decode NAWS subnegotiation" {
  let parsed = @telnet.Parser::default().feed(
    bytes([255, 250, 31, 0, 80, 0, 24, 255, 240]),
  )
  match parsed.events[0] {
    @telnet.Event::Subnegotiation(sb) =>
      match @telnet.OptionPayload::decode(sb.option, sb.payload) {
        Ok(@telnet.OptionPayload::Naws(size)) => {
          assert_true(size.columns == (80).to_uint16())
          assert_true(size.rows == (24).to_uint16())
        }
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}
