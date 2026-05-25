// Exhaustive-ish encoder -> parser roundtrip matrices for TELNET frames.

///|
fn roundtrip_assert_item(
  item : @telnet.EncodeItem,
  expected_events : Array[@telnet.Event],
) -> Unit raise {
  let encoder = @telnet.Encoder::canonical()
  let required = encoder.required_capacity(item)
  let wire = Bytes::new(required)
  match encoder.encode_item(item, wire) {
    Ok(r) => {
      assert_true(r.bytes_written == required)
      let parsed = @telnet.Parser::default().feed(wire)
      assert_true(parsed.bytes_consumed == r.bytes_written)
      assert_true(events_semantically_equal(parsed.events, expected_events))
      assert_true(parsed.parser.finish().events == [])
    }
    Err(_) => assert_true(false)
  }
}

///|
test "roundtrip every encodable simple command through parser" {
  let commands = [
    @telnet.Command::NOP,
    @telnet.Command::DM,
    @telnet.Command::BRK,
    @telnet.Command::IP,
    @telnet.Command::AO,
    @telnet.Command::AYT,
    @telnet.Command::EC,
    @telnet.Command::EL,
    @telnet.Command::GA,
  ]
  commands.each(fn(command) raise {
    roundtrip_assert_item(@telnet.EncodeItem::Command(command), [cmd(command)])
  })
}

///|
test "roundtrip negotiation verbs across registry boundary options" {
  let options = [
    0, 1, 3, 24, 31, 34, 37, 38, 39, 42, 46, 49, 50, 93, 138, 140, 141, 200, 254,
    255,
  ]
  let verbs = [
    @telnet.NegotiationVerb::Will,
    @telnet.NegotiationVerb::Wont,
    @telnet.NegotiationVerb::Do,
    @telnet.NegotiationVerb::Dont,
  ]
  verbs.each(fn(verb) raise {
    options.each(fn(option) raise {
      roundtrip_assert_item(
        @telnet.EncodeItem::Negotiation(neg_event(verb, option)),
        [neg(verb, option)],
      )
    })
  })
}

///|
test "roundtrip escaped data frames through parser" {
  let cases = [[], [65], [255], [65, 255, 66], [255, 255, 255]]
  cases.each(fn(payload) raise {
    let encoder = @telnet.Encoder::canonical()
    let item = @telnet.EncodeItem::EscapedData(span(payload))
    let wire = Bytes::new(encoder.required_capacity(item))
    match encoder.encode_item(item, wire) {
      Ok(_) => {
        let parsed = @telnet.Parser::default().feed(wire)
        let collected = Array::new()
        parsed.events.each(fn(event) raise {
          match event {
            @telnet.Event::Data(d) =>
              for i = 0; i < d.span.length; i = i + 1 {
                collected.push(d.span.bytes[d.span.start + i].to_int())
              }
            _ => assert_true(false)
          }
        })
        assert_true(collected == payload)
      }
      Err(_) => assert_true(false)
    }
  })
}

///|
test "roundtrip representative subnegotiations through parser" {
  let options = [24, 31, 39, 42, 46, 50, 93, 138, 200, 254]
  options.each(fn(option) raise {
    let payload = [1, 65, 255, 66]
    roundtrip_assert_item(
      @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: opt(option),
        payload: span(payload),
      }),
      [sb(option, payload)],
    )
  })
}
