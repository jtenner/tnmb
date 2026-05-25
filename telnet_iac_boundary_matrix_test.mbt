// IAC boundary matrix: streaming splits around TELNET escape bytes.

///|
fn iac_boundary_assert_all_splits(
  wire : Array[Int],
  expected : Array[@telnet.Event],
) -> Unit raise {
  let config = @telnet.Parser::default_config()
  for split = 0; split <= wire.length(); split = split + 1 {
    assert_true(
      events_semantically_equal(tdd_feed_split(config, wire, split), expected),
    )
  }
}

///|
test "IAC boundary escaped IAC before and after command" {
  iac_boundary_assert_all_splits([255, 255, 255, 241, 255, 255], [
    data([255]),
    cmd(@telnet.Command::NOP),
    data([255]),
  ])
}

///|
test "IAC boundary command between data bytes" {
  iac_boundary_assert_all_splits([65, 255, 246, 66, 255, 242, 67], [
    data([65]),
    cmd(@telnet.Command::AYT),
    data([66]),
    cmd(@telnet.Command::DM),
    data([67]),
  ])
}

///|
test "IAC boundary negotiation split at every byte" {
  iac_boundary_assert_all_splits([65, 255, 251, 1, 66, 255, 253, 31, 67], [
    data([65]),
    neg(@telnet.NegotiationVerb::Will, 1),
    data([66]),
    neg(@telnet.NegotiationVerb::Do, 31),
    data([67]),
  ])
}

///|
test "IAC boundary subnegotiation escaped IAC and command after SE" {
  iac_boundary_assert_all_splits(
    [65, 255, 250, 50, 1, 255, 255, 2, 255, 240, 255, 241, 66],
    [data([65]), sb(50, [1, 255, 2]), cmd(@telnet.Command::NOP), data([66])],
  )
}

///|
fn iac_boundary_assert_finish_error(
  wire : Array[Int],
  kind : @telnet.TelnetErrorKind,
) -> Unit raise {
  let fed = @telnet.Parser::default().feed(bytes(wire))
  let finished = fed.parser.finish()
  assert_true(finished.events.length() == 1)
  match finished.events[0] {
    @telnet.Event::Error(e) => assert_true(e.kind == kind)
    _ => assert_true(false)
  }
}

///|
test "IAC boundary dangling IAC produces finish error" {
  iac_boundary_assert_finish_error(
    [255],
    @telnet.TelnetErrorKind::IncompleteIac,
  )
}

///|
test "IAC boundary dangling negotiation produces finish error" {
  iac_boundary_assert_finish_error(
    [255, 251],
    @telnet.TelnetErrorKind::IncompleteNegotiation,
  )
}

///|
test "IAC boundary dangling SB start produces finish error" {
  iac_boundary_assert_finish_error(
    [255, 250],
    @telnet.TelnetErrorKind::IncompleteSubnegotiation,
  )
}

///|
test "IAC boundary dangling SB after IAC produces finish error" {
  iac_boundary_assert_finish_error(
    [255, 250, 24, 1, 255],
    @telnet.TelnetErrorKind::IncompleteSubnegotiation,
  )
}
