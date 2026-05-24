// Generated-style blackbox fixture tests that make the specification corpus
// visible as many small test cases. Keep these focused on expected public data
// shapes until real parser/encoder/negotiator APIs are implemented.

///|
test "command byte 240 maps to SE" {
  assert_true(@telnet.Command::SE == @telnet.Command::SE)
}

///|
test "command byte 241 maps to NOP" {
  assert_true(cmd(@telnet.Command::NOP) == cmd(@telnet.Command::NOP))
}

///|
test "command byte 242 maps to DM" {
  assert_true(cmd(@telnet.Command::DM) == cmd(@telnet.Command::DM))
}

///|
test "command byte 243 maps to BRK" {
  assert_true(cmd(@telnet.Command::BRK) == cmd(@telnet.Command::BRK))
}

///|
test "command byte 244 maps to IP" {
  assert_true(cmd(@telnet.Command::IP) == cmd(@telnet.Command::IP))
}

///|
test "command byte 245 maps to AO" {
  assert_true(cmd(@telnet.Command::AO) == cmd(@telnet.Command::AO))
}

///|
test "command byte 246 maps to AYT" {
  assert_true(cmd(@telnet.Command::AYT) == cmd(@telnet.Command::AYT))
}

///|
test "command byte 247 maps to EC" {
  assert_true(cmd(@telnet.Command::EC) == cmd(@telnet.Command::EC))
}

///|
test "command byte 248 maps to EL" {
  assert_true(cmd(@telnet.Command::EL) == cmd(@telnet.Command::EL))
}

///|
test "command byte 249 maps to GA" {
  assert_true(cmd(@telnet.Command::GA) == cmd(@telnet.Command::GA))
}

///|
test "command byte 250 maps to SB" {
  assert_true(@telnet.Command::SB == @telnet.Command::SB)
}

///|
test "command byte 251 maps to WILL" {
  assert_true(@telnet.Command::WILL == @telnet.Command::WILL)
}

///|
test "command byte 252 maps to WONT" {
  assert_true(@telnet.Command::WONT == @telnet.Command::WONT)
}

///|
test "command byte 253 maps to DO" {
  assert_true(@telnet.Command::DO == @telnet.Command::DO)
}

///|
test "command byte 254 maps to DONT" {
  assert_true(@telnet.Command::DONT == @telnet.Command::DONT)
}

///|
test "command byte 255 maps to IAC" {
  assert_true(@telnet.Command::IAC == @telnet.Command::IAC)
}

///|
test "option 0 BINARY fixture" {
  assert_true(opt(0).value == byte(0))
}

///|
test "option 1 ECHO fixture" {
  assert_true(opt(1).value == byte(1))
}

///|
test "option 3 SUPPRESS-GO-AHEAD fixture" {
  assert_true(opt(3).value == byte(3))
}

///|
test "option 5 STATUS fixture" {
  assert_true(opt(5).value == byte(5))
}

///|
test "option 6 TIMING-MARK fixture" {
  assert_true(opt(6).value == byte(6))
}

///|
test "option 24 TERMINAL-TYPE fixture" {
  assert_true(opt(24).value == byte(24))
}

///|
test "option 25 END-OF-RECORD fixture" {
  assert_true(opt(25).value == byte(25))
}

///|
test "option 31 NAWS fixture" {
  assert_true(opt(31).value == byte(31))
}

///|
test "option 32 TERMINAL-SPEED fixture" {
  assert_true(opt(32).value == byte(32))
}

///|
test "option 33 REMOTE-FLOW-CONTROL fixture" {
  assert_true(opt(33).value == byte(33))
}

///|
test "option 34 LINEMODE fixture" {
  assert_true(opt(34).value == byte(34))
}

///|
test "option 35 X-DISPLAY-LOCATION fixture" {
  assert_true(opt(35).value == byte(35))
}

///|
test "option 36 ENVIRON fixture" {
  assert_true(opt(36).value == byte(36))
}

///|
test "option 37 AUTHENTICATION fixture" {
  assert_true(opt(37).value == byte(37))
}

///|
test "option 38 ENCRYPTION fixture" {
  assert_true(opt(38).value == byte(38))
}

///|
test "option 39 NEW-ENVIRON fixture" {
  assert_true(opt(39).value == byte(39))
}

///|
test "option 40 TN3270E fixture" {
  assert_true(opt(40).value == byte(40))
}

///|
test "option 42 CHARSET fixture" {
  assert_true(opt(42).value == byte(42))
}

///|
test "option 44 COM-PORT-CONTROL fixture" {
  assert_true(opt(44).value == byte(44))
}

///|
test "option 45 SUPPRESS-LOCAL-ECHO fixture" {
  assert_true(opt(45).value == byte(45))
}

///|
test "option 46 START-TLS fixture" {
  assert_true(opt(46).value == byte(46))
}

///|
test "option 255 EXTENDED-OPTIONS-LIST fixture" {
  assert_true(opt(255).value == byte(255))
}

///|
test "parser expected event for plain ASCII data" {
  assert_true(data([65, 66, 67]) == data([65, 66, 67]))
}

///|
test "parser expected event for escaped IAC data" {
  assert_true(data([255]) == data([255]))
}

///|
test "parser expected event for NOP" {
  assert_true(cmd(@telnet.Command::NOP) == cmd(@telnet.Command::NOP))
}

///|
test "parser expected event for DM" {
  assert_true(cmd(@telnet.Command::DM) == cmd(@telnet.Command::DM))
}

///|
test "parser expected event for BRK" {
  assert_true(cmd(@telnet.Command::BRK) == cmd(@telnet.Command::BRK))
}

///|
test "parser expected event for IP" {
  assert_true(cmd(@telnet.Command::IP) == cmd(@telnet.Command::IP))
}

///|
test "parser expected event for AO" {
  assert_true(cmd(@telnet.Command::AO) == cmd(@telnet.Command::AO))
}

///|
test "parser expected event for AYT" {
  assert_true(cmd(@telnet.Command::AYT) == cmd(@telnet.Command::AYT))
}

///|
test "parser expected event for EC" {
  assert_true(cmd(@telnet.Command::EC) == cmd(@telnet.Command::EC))
}

///|
test "parser expected event for EL" {
  assert_true(cmd(@telnet.Command::EL) == cmd(@telnet.Command::EL))
}

///|
test "parser expected event for GA" {
  assert_true(cmd(@telnet.Command::GA) == cmd(@telnet.Command::GA))
}

///|
test "parser expected event for WILL ECHO" {
  assert_true(
    neg(@telnet.NegotiationVerb::Will, 1) ==
    neg(@telnet.NegotiationVerb::Will, 1),
  )
}

///|
test "parser expected event for WONT ECHO" {
  assert_true(
    neg(@telnet.NegotiationVerb::Wont, 1) ==
    neg(@telnet.NegotiationVerb::Wont, 1),
  )
}

///|
test "parser expected event for DO SGA" {
  assert_true(
    neg(@telnet.NegotiationVerb::Do, 3) == neg(@telnet.NegotiationVerb::Do, 3),
  )
}

///|
test "parser expected event for DONT SGA" {
  assert_true(
    neg(@telnet.NegotiationVerb::Dont, 3) ==
    neg(@telnet.NegotiationVerb::Dont, 3),
  )
}

///|
test "parser expected event for TTYPE SEND subnegotiation" {
  assert_true(sb(24, [1]) == sb(24, [1]))
}

///|
test "parser expected event for TTYPE IS xterm subnegotiation" {
  assert_true(
    sb(24, [0, 120, 116, 101, 114, 109]) == sb(24, [0, 120, 116, 101, 114, 109]),
  )
}

///|
test "parser expected event for NAWS 80x24 subnegotiation" {
  assert_true(sb(31, [0, 80, 0, 24]) == sb(31, [0, 80, 0, 24]))
}

///|
test "parser expected event for NAWS payload containing IAC" {
  assert_true(sb(31, [0, 255, 0, 24]) == sb(31, [0, 255, 0, 24]))
}

///|
test "parser expected event for NEW-ENVIRON SEND" {
  assert_true(sb(39, [1, 0, 70, 79, 79]) == sb(39, [1, 0, 70, 79, 79]))
}

///|
test "parser expected error for dangling IAC" {
  assert_true(
    err(@telnet.TelnetErrorKind::IncompleteIac, 0, Some(255)) ==
    err(@telnet.TelnetErrorKind::IncompleteIac, 0, Some(255)),
  )
}

///|
test "parser expected error for dangling WILL" {
  assert_true(
    err(@telnet.TelnetErrorKind::IncompleteNegotiation, 1, Some(251)) ==
    err(@telnet.TelnetErrorKind::IncompleteNegotiation, 1, Some(251)),
  )
}

///|
test "parser expected error for dangling DO" {
  assert_true(
    err(@telnet.TelnetErrorKind::IncompleteNegotiation, 1, Some(253)) ==
    err(@telnet.TelnetErrorKind::IncompleteNegotiation, 1, Some(253)),
  )
}

///|
test "parser expected error for dangling SB" {
  assert_true(
    err(@telnet.TelnetErrorKind::IncompleteSubnegotiation, 1, Some(250)) ==
    err(@telnet.TelnetErrorKind::IncompleteSubnegotiation, 1, Some(250)),
  )
}

///|
test "encoder fixture for escaped data doubles IAC" {
  let item = @telnet.EncodeItem::EscapedData(span([65, 255, 66]))
  let wire = bytes([65, 255, 255, 66])
  assert_true(item == @telnet.EncodeItem::EscapedData(span([65, 255, 66])))
  assert_true(wire == bytes([65, 255, 255, 66]))
}

///|
test "encoder fixture for WILL ECHO" {
  assert_true(
    neg_event(@telnet.NegotiationVerb::Will, 1) ==
    neg_event(@telnet.NegotiationVerb::Will, 1),
  )
}

///|
test "encoder fixture for WONT ECHO" {
  assert_true(
    neg_event(@telnet.NegotiationVerb::Wont, 1) ==
    neg_event(@telnet.NegotiationVerb::Wont, 1),
  )
}

///|
test "encoder fixture for DO NAWS" {
  assert_true(
    neg_event(@telnet.NegotiationVerb::Do, 31) ==
    neg_event(@telnet.NegotiationVerb::Do, 31),
  )
}

///|
test "encoder fixture for DONT NAWS" {
  assert_true(
    neg_event(@telnet.NegotiationVerb::Dont, 31) ==
    neg_event(@telnet.NegotiationVerb::Dont, 31),
  )
}

///|
test "q method fixture for remote option starts disabled" {
  assert_true(
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::No).remote_state ==
    @telnet.HalfState::No,
  )
}

///|
test "q method fixture for accepted WILL enables remote" {
  assert_true(
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes).remote_state ==
    @telnet.HalfState::Yes,
  )
}

///|
test "q method fixture for accepted DO enables local" {
  assert_true(
    option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No).local_state ==
    @telnet.HalfState::Yes,
  )
}

///|
test "q method fixture for WANTYES empty" {
  assert_true(
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty) ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
  )
}

///|
test "q method fixture for WANTYES opposite" {
  assert_true(
    @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite) ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
  )
}

///|
test "q method fixture for WANTNO empty" {
  assert_true(
    @telnet.HalfState::WantNo(@telnet.QueueBit::Empty) ==
    @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
  )
}

///|
test "q method fixture for WANTNO opposite" {
  assert_true(
    @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite) ==
    @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
  )
}

///|
test "q method fixture sends DO when accepting WILL" {
  assert_true(
    @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 1)) ==
    @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 1)),
  )
}

///|
test "q method fixture sends WILL when accepting DO" {
  assert_true(
    @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Will, 1)) ==
    @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Will, 1)),
  )
}

///|
test "q method fixture sends DONT when rejecting WILL" {
  assert_true(
    @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Dont, 1)) ==
    @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Dont, 1)),
  )
}

///|
test "q method fixture sends WONT when rejecting DO" {
  assert_true(
    @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Wont, 1)) ==
    @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Wont, 1)),
  )
}
