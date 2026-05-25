// Additional compact differential reference tests for complete TELNET streams.

///|
fn diff_ref_parse_complete(wire : Array[Int]) -> Array[@telnet.Event] raise {
  let events = Array::new()
  let data_buf = Array::new()
  let mut i = 0
  while i < wire.length() {
    let x = wire[i]
    if x != 255 {
      data_buf.push(byte(x))
      i = i + 1
    } else {
      if data_buf.length() > 0 {
        events.push(data(data_buf.map(fn(b) { b.to_int() })))
        data_buf.clear()
      }
      let c = wire[i + 1]
      if c == 255 {
        events.push(data([255]))
        i = i + 2
      } else if c >= 241 && c <= 249 {
        match @telnet.Command::from_byte(byte(c)) {
          Some(command) => events.push(cmd(command))
          None => assert_true(false)
        }
        i = i + 2
      } else if c >= 251 && c <= 254 {
        let verb = match c {
          251 => @telnet.NegotiationVerb::Will
          252 => @telnet.NegotiationVerb::Wont
          253 => @telnet.NegotiationVerb::Do
          _ => @telnet.NegotiationVerb::Dont
        }
        events.push(neg(verb, wire[i + 2]))
        i = i + 3
      } else {
        assert_true(false)
      }
    }
  }
  if data_buf.length() > 0 {
    events.push(data(data_buf.map(fn(b) { b.to_int() })))
  }
  events
}

///|
fn diff_assert(wire : Array[Int]) -> Unit raise {
  let expected = diff_ref_parse_complete(wire)
  let parsed = @telnet.Parser::default().feed(bytes(wire))
  assert_true(events_semantically_equal(parsed.events, expected))
  assert_true(parsed.parser.finish().events == [])
}

///|
test "differential reference mixed complete command streams" {
  diff_assert([65, 66, 255, 241, 67, 255, 255, 68])
  diff_assert([255, 251, 1, 255, 253, 31, 72, 105])
  diff_assert([255, 244, 255, 242, 255, 245, 255, 242])
  diff_assert([0, 255, 255, 1, 255, 246, 2, 255, 255, 3])
}

///|
test "differential reference generated negotiation/data sequences" {
  for option = 0; option <= 32; option = option + 4 {
    diff_assert([65, 255, 251, option, 66, 255, 253, option, 67])
    diff_assert([255, 252, option, 255, 254, option, 255, 255])
  }
}
