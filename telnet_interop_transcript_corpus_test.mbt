// Small interop-inspired TELNET transcripts from common client/server patterns.
// These are deterministic corpus tests, not live network tests.

///|
fn interop_assert_stream(
  chunks : Array[Array[Int]],
  expected : Array[@telnet.Event],
) -> Unit raise {
  let mut parser = @telnet.Parser::default()
  let mut events : Array[@telnet.Event] = []
  chunks.each(fn(chunk) {
    let r = parser.feed(bytes(chunk))
    events = events + r.events
    parser = r.parser
  })
  events = events + parser.finish().events
  assert_true(events_semantically_equal(events, expected))
}

///|
test "interop corpus BSD-like initial negotiation burst" {
  interop_assert_stream(
    [[255, 251, 1, 255, 251, 3], [255, 253, 31, 255, 253, 24]],
    [
      neg(@telnet.NegotiationVerb::Will, 1),
      neg(@telnet.NegotiationVerb::Will, 3),
      neg(@telnet.NegotiationVerb::Do, 31),
      neg(@telnet.NegotiationVerb::Do, 24),
    ],
  )
}

///|
test "interop corpus telnetlib-style cooked text around IAC commands" {
  interop_assert_stream(
    [
      [87, 101, 108, 99, 111, 109, 101, 13, 10],
      [255, 246],
      [80, 114, 111, 109, 112, 116, 62, 32],
    ],
    [
      data([87, 101, 108, 99, 111, 109, 101, 13, 10]),
      cmd(@telnet.Command::AYT),
      data([80, 114, 111, 109, 112, 116, 62, 32]),
    ],
  )
}

///|
test "interop corpus MUD GMCP-style private option remains raw" {
  // GMCP commonly uses private option 201. The core should preserve it raw.
  interop_assert_stream(
    [
      [255, 251, 201],
      [255, 250, 201, 67, 111, 114, 101, 46, 72, 101, 108, 108, 111, 255, 240],
    ],
    [
      neg(@telnet.NegotiationVerb::Will, 201),
      sb(201, [67, 111, 114, 101, 46, 72, 101, 108, 108, 111]),
    ],
  )
  match @telnet.OptionPayload::decode(opt(201), span([67, 111, 114, 101])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Raw(opt(201), span([67, 111, 114, 101])),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "interop corpus MUD MCCP option negotiation remains lossless unknown" {
  // MCCP v2 usually uses private option 86. Keep negotiation and SB bytes intact.
  interop_assert_stream([[255, 251, 86], [255, 250, 86, 255, 240]], [
    neg(@telnet.NegotiationVerb::Will, 86),
    sb(86, []),
  ])
  assert_true(
    @telnet.KnownOption::from_code(opt(86)) ==
    @telnet.KnownOption::Unknown(opt(86)),
  )
}

///|
test "interop corpus TTYPE cycling requests are visible as repeated SEND payloads" {
  interop_assert_stream(
    [
      [255, 250, 24, 1, 255, 240],
      [255, 250, 24, 1, 255, 240],
      [255, 250, 24, 1, 255, 240],
    ],
    [sb(24, [1]), sb(24, [1]), sb(24, [1])],
  )
}

///|
test "interop corpus NAWS resize stream preserves every update" {
  interop_assert_stream(
    [
      [255, 250, 31, 0, 80, 0, 24, 255, 240],
      [255, 250, 31, 0, 100, 0, 40, 255, 240],
      [255, 250, 31, 1, 44, 0, 60, 255, 240],
    ],
    [sb(31, [0, 80, 0, 24]), sb(31, [0, 100, 0, 40]), sb(31, [1, 44, 0, 60])],
  )
}

///|
test "interop corpus escaped IAC in binary-like application data" {
  interop_assert_stream([[0, 1, 255, 255, 2], [255, 241], [3, 255, 255, 4]], [
    data([0, 1]),
    data([255]),
    data([2]),
    cmd(@telnet.Command::NOP),
    data([3]),
    data([255]),
    data([4]),
  ])
}

///|
test "interop corpus ECHO password flow remains negotiation plus data" {
  interop_assert_stream(
    [
      [85, 115, 101, 114, 58, 32],
      [255, 251, 1],
      [80, 97, 115, 115, 58, 32],
      [255, 252, 1],
      [79, 75, 13, 10],
    ],
    [
      data([85, 115, 101, 114, 58, 32]),
      neg(@telnet.NegotiationVerb::Will, 1),
      data([80, 97, 115, 115, 58, 32]),
      neg(@telnet.NegotiationVerb::Wont, 1),
      data([79, 75, 13, 10]),
    ],
  )
}

///|
test "interop corpus SGA and ECHO char-mode negotiation burst" {
  interop_assert_stream(
    [[255, 251, 3, 255, 251, 1], [255, 253, 3, 255, 253, 1], [62, 32]],
    [
      neg(@telnet.NegotiationVerb::Will, 3),
      neg(@telnet.NegotiationVerb::Will, 1),
      neg(@telnet.NegotiationVerb::Do, 3),
      neg(@telnet.NegotiationVerb::Do, 1),
      data([62, 32]),
    ],
  )
}

///|
test "interop corpus private MSDP and MSSP options stay raw" {
  interop_assert_stream(
    [
      [
        255, 251, 69, 255, 250, 69, 1, 80, 76, 65, 89, 69, 82, 83, 2, 52, 50, 255,
        240,
      ],
      [255, 251, 70, 255, 250, 70, 1, 78, 65, 77, 69, 2, 77, 85, 68, 255, 240],
    ],
    [
      neg(@telnet.NegotiationVerb::Will, 69),
      sb(69, [1, 80, 76, 65, 89, 69, 82, 83, 2, 52, 50]),
      neg(@telnet.NegotiationVerb::Will, 70),
      sb(70, [1, 78, 65, 77, 69, 2, 77, 85, 68]),
    ],
  )
}

///|
test "interop corpus standalone SE recovers before later data" {
  interop_assert_stream([[255, 240], [65, 66], [255, 241]], [
    err(@telnet.TelnetErrorKind::UnexpectedSubnegotiationEnd, 1, Some(240)),
    data([65, 66]),
    cmd(@telnet.Command::NOP),
  ])
}

///|
test "interop corpus DM synch command sequences stay visible" {
  interop_assert_stream([[255, 242, 255, 244], [255, 242, 68, 111, 110, 101]], [
    cmd(@telnet.Command::DM),
    cmd(@telnet.Command::IP),
    cmd(@telnet.Command::DM),
    data([68, 111, 110, 101]),
  ])
}

///|
test "interop corpus EOR negotiation and record-boundary shapes" {
  // RFC 885 assigns option 25 and command byte 239. The current public command
  // enum does not model byte 239, so strict parser behavior is characterized
  // while negotiation and raw SB framing remain lossless.
  interop_assert_stream(
    [[255, 253, 25, 65, 66], [255, 239], [255, 250, 25, 82, 69, 67, 255, 240]],
    [
      neg(@telnet.NegotiationVerb::Do, 25),
      data([65, 66]),
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 6, Some(239)),
      sb(25, [82, 69, 67]),
    ],
  )
  match @telnet.OptionPayload::decode(opt(25), span([82, 69, 67])) {
    Ok(payload) =>
      assert_true(
        payload == @telnet.OptionPayload::Raw(opt(25), span([82, 69, 67])),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "interop corpus STATUS and X-DISPLAY-LOCATION raw payloads" {
  interop_assert_stream(
    [
      [255, 253, 5, 255, 250, 5, 1, 251, 3, 253, 1, 255, 240],
      [
        255, 251, 35, 255, 250, 35, 100, 105, 115, 112, 108, 97, 121, 58, 48, 255,
        240,
      ],
    ],
    [
      neg(@telnet.NegotiationVerb::Do, 5),
      sb(5, [1, 251, 3, 253, 1]),
      neg(@telnet.NegotiationVerb::Will, 35),
      sb(35, [100, 105, 115, 112, 108, 97, 121, 58, 48]),
    ],
  )
  match @telnet.OptionPayload::decode(opt(5), span([1, 251, 3, 253, 1])) {
    Ok(payload) =>
      assert_true(
        payload == @telnet.OptionPayload::Raw(opt(5), span([1, 251, 3, 253, 1])),
      )
    Err(_) => assert_true(false)
  }
  match
    @telnet.OptionPayload::decode(
      opt(35),
      span([100, 105, 115, 112, 108, 97, 121, 58, 48]),
    ) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Raw(
          opt(35),
          span([100, 105, 115, 112, 108, 97, 121, 58, 48]),
        ),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "interop corpus NEW-ENVIRON IS SEND and escaped variables decode" {
  interop_assert_stream(
    [
      [255, 250, 39, 0, 0, 84, 69, 82, 77, 1, 120, 116, 101, 114, 109, 255, 240],
      [255, 250, 39, 1, 0, 85, 83, 69, 82, 3, 76, 79, 67, 65, 76, 255, 240],
      [
        255, 250, 39, 0, 0, 2, 0, 78, 1, 2, 1, 86, 2, 2, 33, 3, 85, 1, 103, 117,
        101, 115, 116, 255, 240,
      ],
    ],
    [
      sb(39, [0, 0, 84, 69, 82, 77, 1, 120, 116, 101, 114, 109]),
      sb(39, [1, 0, 85, 83, 69, 82, 3, 76, 79, 67, 65, 76]),
      sb(39, [
        0, 0, 2, 0, 78, 1, 2, 1, 86, 2, 2, 33, 3, 85, 1, 103, 117, 101, 115, 116,
      ]),
    ],
  )
  match
    @telnet.OptionPayload::decode(
      opt(39),
      span([0, 0, 84, 69, 82, 77, 1, 120, 116, 101, 114, 109]),
    ) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Environment(
          @telnet.EnvironmentMessage::Is([
            @telnet.EnvironmentVariable::{
              kind: @telnet.EnvironmentVariableKind::Var,
              name: "TERM",
              value: Some("xterm"),
            },
          ]),
        ),
      )
    Err(_) => assert_true(false)
  }
  match
    @telnet.OptionPayload::decode(
      opt(39),
      span([1, 0, 85, 83, 69, 82, 3, 76, 79, 67, 65, 76]),
    ) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Environment(
          @telnet.EnvironmentMessage::Send(["USER", "LOCAL"]),
        ),
      )
    Err(_) => assert_true(false)
  }
  match
    @telnet.OptionPayload::decode(
      opt(39),
      span([
        0, 0, 2, 0, 78, 1, 2, 1, 86, 2, 2, 33, 3, 85, 1, 103, 117, 101, 115, 116,
      ]),
    ) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Environment(
          @telnet.EnvironmentMessage::Is([
            @telnet.EnvironmentVariable::{
              kind: @telnet.EnvironmentVariableKind::Var,
              name: "\u{0}N",
              value: Some("\u{1}V\u{2}!"),
            },
            @telnet.EnvironmentVariable::{
              kind: @telnet.EnvironmentVariableKind::UserVar,
              name: "U",
              value: Some("guest"),
            },
          ]),
        ),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "interop corpus AUTH ENCRYPT KERMIT SEND-URL FORWARD-X raw transcripts" {
  interop_assert_stream(
    [
      [255, 253, 37, 255, 251, 38],
      [255, 253, 47, 255, 250, 47, 1, 35, 83, 255, 240],
      [
        255, 253, 48, 255, 250, 48, 104, 116, 116, 112, 58, 47, 47, 120, 255, 240,
      ],
      [255, 253, 49, 255, 250, 49, 127, 128, 254, 255, 255, 0, 255, 240],
    ],
    [
      neg(@telnet.NegotiationVerb::Do, 37),
      neg(@telnet.NegotiationVerb::Will, 38),
      neg(@telnet.NegotiationVerb::Do, 47),
      sb(47, [1, 35, 83]),
      neg(@telnet.NegotiationVerb::Do, 48),
      sb(48, [104, 116, 116, 112, 58, 47, 47, 120]),
      neg(@telnet.NegotiationVerb::Do, 49),
      sb(49, [127, 128, 254, 255, 0]),
    ],
  )
  match @telnet.OptionPayload::decode(opt(47), span([1, 35, 83])) {
    Ok(payload) =>
      assert_true(
        payload == @telnet.OptionPayload::Raw(opt(47), span([1, 35, 83])),
      )
    Err(_) => assert_true(false)
  }
  match
    @telnet.OptionPayload::decode(
      opt(48),
      span([104, 116, 116, 112, 58, 47, 47, 120]),
    ) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Raw(
          opt(48),
          span([104, 116, 116, 112, 58, 47, 47, 120]),
        ),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.OptionPayload::decode(opt(49), span([127, 128, 254, 255, 0])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Raw(opt(49), span([127, 128, 254, 255, 0])),
      )
    Err(_) => assert_true(false)
  }
}
