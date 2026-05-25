// Independent reference checks for complete streams containing subnegotiations.

///|
fn diff_ref_parse_complete_with_sb(
  wire : Array[Int],
) -> Array[@telnet.Event] raise {
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
      } else if c == 250 {
        let option = wire[i + 2]
        let payload = Array::new()
        i = i + 3
        let mut done = false
        while !done {
          if wire[i] == 255 && wire[i + 1] == 255 {
            payload.push(255)
            i = i + 2
          } else if wire[i] == 255 && wire[i + 1] == 240 {
            events.push(sb(option, payload))
            i = i + 2
            done = true
          } else {
            payload.push(wire[i])
            i = i + 1
          }
        }
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
fn diff_assert_with_sb(wire : Array[Int]) -> Unit raise {
  let expected = diff_ref_parse_complete_with_sb(wire)
  let parsed = @telnet.Parser::default().feed(bytes(wire))
  assert_true(events_semantically_equal(parsed.events, expected))
  assert_true(parsed.parser.finish().events == [])
}

///|
test "differential reference complete streams with subnegotiations" {
  diff_assert_with_sb([65, 255, 250, 24, 1, 255, 240, 66])
  diff_assert_with_sb([255, 250, 31, 0, 80, 0, 24, 255, 240])
  diff_assert_with_sb([
    255, 251, 24, 255, 250, 24, 0, 88, 84, 69, 82, 77, 255, 240,
  ])
  diff_assert_with_sb([255, 250, 200, 1, 255, 255, 2, 255, 240, 255, 241])
}

///|
test "differential reference generated complete SB cases" {
  let options = [24, 31, 34, 46, 50, 138, 201]
  let payloads = [[1], [0, 1], [65, 255, 66], []]
  options.each(fn(option) raise {
    payloads.each(fn(payload) raise {
      let escaped = Array::new()
      payload.each(fn(x) {
        escaped.push(x)
        if x == 255 {
          escaped.push(255)
        }
      })
      diff_assert_with_sb([255, 250, option] + escaped + [255, 240])
    })
  })
}
