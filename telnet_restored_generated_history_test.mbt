// More restored generated/history coverage converted from removed no-op fixture files.
// Every case below calls production parser, encoder, mapping, negotiator, or codec APIs.

///|
fn restored_gen_assert_encoded(
  item : @telnet.EncodeItem,
  expected : Array[Int],
) -> Unit raise {
  let out = Bytes::new(expected.length())
  match @telnet.Encoder::canonical().encode_item(item, out) {
    Ok(r) => {
      assert_true(r.bytes_written == expected.length())
      assert_true(r.required_capacity == expected.length())
      assert_true(out == bytes(expected))
    }
    Err(_) => assert_true(false)
  }
}

///|
fn restored_gen_assert_parse(
  wire : Array[Int],
  expected : Array[@telnet.Event],
) -> Unit raise {
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.bytes_consumed == wire.length())
  assert_true(result.events == expected)
}

///|
fn restored_gen_assert_decode(
  option : Int,
  payload : Array[Int],
  expected : @telnet.OptionPayload,
) -> Unit raise {
  match @telnet.OptionPayload::decode(opt(option), span(payload)) {
    Ok(decoded) => assert_true(decoded == expected)
    Err(_) => assert_true(false)
  }
}

///|
test "restored generated command byte 240 maps through public helpers" {
  match @telnet.Command::from_byte(byte(240)) {
    Some(c) => {
      assert_true(c == @telnet.Command::SE)
      assert_true(c.to_byte() == byte(240))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 241 maps through public helpers" {
  match @telnet.Command::from_byte(byte(241)) {
    Some(c) => {
      assert_true(c == @telnet.Command::NOP)
      assert_true(c.to_byte() == byte(241))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 242 maps through public helpers" {
  match @telnet.Command::from_byte(byte(242)) {
    Some(c) => {
      assert_true(c == @telnet.Command::DM)
      assert_true(c.to_byte() == byte(242))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 243 maps through public helpers" {
  match @telnet.Command::from_byte(byte(243)) {
    Some(c) => {
      assert_true(c == @telnet.Command::BRK)
      assert_true(c.to_byte() == byte(243))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 244 maps through public helpers" {
  match @telnet.Command::from_byte(byte(244)) {
    Some(c) => {
      assert_true(c == @telnet.Command::IP)
      assert_true(c.to_byte() == byte(244))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 245 maps through public helpers" {
  match @telnet.Command::from_byte(byte(245)) {
    Some(c) => {
      assert_true(c == @telnet.Command::AO)
      assert_true(c.to_byte() == byte(245))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 246 maps through public helpers" {
  match @telnet.Command::from_byte(byte(246)) {
    Some(c) => {
      assert_true(c == @telnet.Command::AYT)
      assert_true(c.to_byte() == byte(246))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 247 maps through public helpers" {
  match @telnet.Command::from_byte(byte(247)) {
    Some(c) => {
      assert_true(c == @telnet.Command::EC)
      assert_true(c.to_byte() == byte(247))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 248 maps through public helpers" {
  match @telnet.Command::from_byte(byte(248)) {
    Some(c) => {
      assert_true(c == @telnet.Command::EL)
      assert_true(c.to_byte() == byte(248))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 249 maps through public helpers" {
  match @telnet.Command::from_byte(byte(249)) {
    Some(c) => {
      assert_true(c == @telnet.Command::GA)
      assert_true(c.to_byte() == byte(249))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 250 maps through public helpers" {
  match @telnet.Command::from_byte(byte(250)) {
    Some(c) => {
      assert_true(c == @telnet.Command::SB)
      assert_true(c.to_byte() == byte(250))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 251 maps through public helpers" {
  match @telnet.Command::from_byte(byte(251)) {
    Some(c) => {
      assert_true(c == @telnet.Command::WILL)
      assert_true(c.to_byte() == byte(251))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 252 maps through public helpers" {
  match @telnet.Command::from_byte(byte(252)) {
    Some(c) => {
      assert_true(c == @telnet.Command::WONT)
      assert_true(c.to_byte() == byte(252))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 253 maps through public helpers" {
  match @telnet.Command::from_byte(byte(253)) {
    Some(c) => {
      assert_true(c == @telnet.Command::DO)
      assert_true(c.to_byte() == byte(253))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 254 maps through public helpers" {
  match @telnet.Command::from_byte(byte(254)) {
    Some(c) => {
      assert_true(c == @telnet.Command::DONT)
      assert_true(c.to_byte() == byte(254))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated command byte 255 maps through public helpers" {
  match @telnet.Command::from_byte(byte(255)) {
    Some(c) => {
      assert_true(c == @telnet.Command::IAC)
      assert_true(c.to_byte() == byte(255))
    }
    None => assert_true(false)
  }
}

///|
test "restored generated parser emits simple command NOP" {
  restored_gen_assert_parse([255, 241], [cmd(@telnet.Command::NOP)])
}

///|
test "restored generated parser emits simple command DM" {
  restored_gen_assert_parse([255, 242], [cmd(@telnet.Command::DM)])
}

///|
test "restored generated parser emits simple command BRK" {
  restored_gen_assert_parse([255, 243], [cmd(@telnet.Command::BRK)])
}

///|
test "restored generated parser emits simple command IP" {
  restored_gen_assert_parse([255, 244], [cmd(@telnet.Command::IP)])
}

///|
test "restored generated parser emits simple command AO" {
  restored_gen_assert_parse([255, 245], [cmd(@telnet.Command::AO)])
}

///|
test "restored generated parser emits simple command AYT" {
  restored_gen_assert_parse([255, 246], [cmd(@telnet.Command::AYT)])
}

///|
test "restored generated parser emits simple command EC" {
  restored_gen_assert_parse([255, 247], [cmd(@telnet.Command::EC)])
}

///|
test "restored generated parser emits simple command EL" {
  restored_gen_assert_parse([255, 248], [cmd(@telnet.Command::EL)])
}

///|
test "restored generated parser emits simple command GA" {
  restored_gen_assert_parse([255, 249], [cmd(@telnet.Command::GA)])
}

///|
test "restored generated encoder writes simple command NOP" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Command(@telnet.Command::NOP),
    [255, 241],
  )
}

///|
test "restored generated encoder writes simple command DM" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Command(@telnet.Command::DM),
    [255, 242],
  )
}

///|
test "restored generated encoder writes simple command BRK" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Command(@telnet.Command::BRK),
    [255, 243],
  )
}

///|
test "restored generated encoder writes simple command IP" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Command(@telnet.Command::IP),
    [255, 244],
  )
}

///|
test "restored generated encoder writes simple command AO" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Command(@telnet.Command::AO),
    [255, 245],
  )
}

///|
test "restored generated encoder writes simple command AYT" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Command(@telnet.Command::AYT),
    [255, 246],
  )
}

///|
test "restored generated encoder writes simple command EC" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Command(@telnet.Command::EC),
    [255, 247],
  )
}

///|
test "restored generated encoder writes simple command EL" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Command(@telnet.Command::EL),
    [255, 248],
  )
}

///|
test "restored generated encoder writes simple command GA" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Command(@telnet.Command::GA),
    [255, 249],
  )
}

///|
test "restored generated invalid IAC byte 0 reports parser error" {
  restored_gen_assert_parse([255, 0], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(0)),
  ])
  assert_true(@telnet.Command::from_byte(byte(0)) == None)
}

///|
test "restored generated invalid IAC byte 1 reports parser error" {
  restored_gen_assert_parse([255, 1], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(1)),
  ])
  assert_true(@telnet.Command::from_byte(byte(1)) == None)
}

///|
test "restored generated invalid IAC byte 2 reports parser error" {
  restored_gen_assert_parse([255, 2], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(2)),
  ])
  assert_true(@telnet.Command::from_byte(byte(2)) == None)
}

///|
test "restored generated invalid IAC byte 10 reports parser error" {
  restored_gen_assert_parse([255, 10], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(10)),
  ])
  assert_true(@telnet.Command::from_byte(byte(10)) == None)
}

///|
test "restored generated invalid IAC byte 13 reports parser error" {
  restored_gen_assert_parse([255, 13], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(13)),
  ])
  assert_true(@telnet.Command::from_byte(byte(13)) == None)
}

///|
test "restored generated invalid IAC byte 31 reports parser error" {
  restored_gen_assert_parse([255, 31], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(31)),
  ])
  assert_true(@telnet.Command::from_byte(byte(31)) == None)
}

///|
test "restored generated invalid IAC byte 42 reports parser error" {
  restored_gen_assert_parse([255, 42], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(42)),
  ])
  assert_true(@telnet.Command::from_byte(byte(42)) == None)
}

///|
test "restored generated invalid IAC byte 100 reports parser error" {
  restored_gen_assert_parse([255, 100], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(100)),
  ])
  assert_true(@telnet.Command::from_byte(byte(100)) == None)
}

///|
test "restored generated invalid IAC byte 127 reports parser error" {
  restored_gen_assert_parse([255, 127], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(127)),
  ])
  assert_true(@telnet.Command::from_byte(byte(127)) == None)
}

///|
test "restored generated invalid IAC byte 128 reports parser error" {
  restored_gen_assert_parse([255, 128], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(128)),
  ])
  assert_true(@telnet.Command::from_byte(byte(128)) == None)
}

///|
test "restored generated invalid IAC byte 200 reports parser error" {
  restored_gen_assert_parse([255, 200], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(200)),
  ])
  assert_true(@telnet.Command::from_byte(byte(200)) == None)
}

///|
test "restored generated invalid IAC byte 239 reports parser error" {
  restored_gen_assert_parse([255, 239], [
    err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(239)),
  ])
  assert_true(@telnet.Command::from_byte(byte(239)) == None)
}

///|
test "restored generated known option 0 maps to Binary" {
  let known = @telnet.KnownOption::from_code(opt(0))
  assert_true(known == @telnet.KnownOption::Binary)
  assert_true(known.to_code() == opt(0))
}

///|
test "restored generated known option 1 maps to Echo" {
  let known = @telnet.KnownOption::from_code(opt(1))
  assert_true(known == @telnet.KnownOption::Echo)
  assert_true(known.to_code() == opt(1))
}

///|
test "restored generated known option 2 maps to Reconnection" {
  let known = @telnet.KnownOption::from_code(opt(2))
  assert_true(known == @telnet.KnownOption::Reconnection)
  assert_true(known.to_code() == opt(2))
}

///|
test "restored generated known option 3 maps to SuppressGoAhead" {
  let known = @telnet.KnownOption::from_code(opt(3))
  assert_true(known == @telnet.KnownOption::SuppressGoAhead)
  assert_true(known.to_code() == opt(3))
}

///|
test "restored generated known option 4 maps to ApproxMessageSizeNegotiation" {
  let known = @telnet.KnownOption::from_code(opt(4))
  assert_true(known == @telnet.KnownOption::ApproxMessageSizeNegotiation)
  assert_true(known.to_code() == opt(4))
}

///|
test "restored generated known option 5 maps to Status" {
  let known = @telnet.KnownOption::from_code(opt(5))
  assert_true(known == @telnet.KnownOption::Status)
  assert_true(known.to_code() == opt(5))
}

///|
test "restored generated known option 6 maps to TimingMark" {
  let known = @telnet.KnownOption::from_code(opt(6))
  assert_true(known == @telnet.KnownOption::TimingMark)
  assert_true(known.to_code() == opt(6))
}

///|
test "restored generated known option 7 maps to RemoteControlledTransAndEcho" {
  let known = @telnet.KnownOption::from_code(opt(7))
  assert_true(known == @telnet.KnownOption::RemoteControlledTransAndEcho)
  assert_true(known.to_code() == opt(7))
}

///|
test "restored generated known option 8 maps to OutputLineWidth" {
  let known = @telnet.KnownOption::from_code(opt(8))
  assert_true(known == @telnet.KnownOption::OutputLineWidth)
  assert_true(known.to_code() == opt(8))
}

///|
test "restored generated known option 9 maps to OutputPageSize" {
  let known = @telnet.KnownOption::from_code(opt(9))
  assert_true(known == @telnet.KnownOption::OutputPageSize)
  assert_true(known.to_code() == opt(9))
}

///|
test "restored generated known option 10 maps to OutputCarriageReturnDisposition" {
  let known = @telnet.KnownOption::from_code(opt(10))
  assert_true(known == @telnet.KnownOption::OutputCarriageReturnDisposition)
  assert_true(known.to_code() == opt(10))
}

///|
test "restored generated known option 11 maps to OutputHorizontalTabStops" {
  let known = @telnet.KnownOption::from_code(opt(11))
  assert_true(known == @telnet.KnownOption::OutputHorizontalTabStops)
  assert_true(known.to_code() == opt(11))
}

///|
test "restored generated known option 12 maps to OutputHorizontalTabDisposition" {
  let known = @telnet.KnownOption::from_code(opt(12))
  assert_true(known == @telnet.KnownOption::OutputHorizontalTabDisposition)
  assert_true(known.to_code() == opt(12))
}

///|
test "restored generated known option 13 maps to OutputFormfeedDisposition" {
  let known = @telnet.KnownOption::from_code(opt(13))
  assert_true(known == @telnet.KnownOption::OutputFormfeedDisposition)
  assert_true(known.to_code() == opt(13))
}

///|
test "restored generated known option 14 maps to OutputVerticalTabStops" {
  let known = @telnet.KnownOption::from_code(opt(14))
  assert_true(known == @telnet.KnownOption::OutputVerticalTabStops)
  assert_true(known.to_code() == opt(14))
}

///|
test "restored generated known option 15 maps to OutputVerticalTabDisposition" {
  let known = @telnet.KnownOption::from_code(opt(15))
  assert_true(known == @telnet.KnownOption::OutputVerticalTabDisposition)
  assert_true(known.to_code() == opt(15))
}

///|
test "restored generated known option 16 maps to OutputLinefeedDisposition" {
  let known = @telnet.KnownOption::from_code(opt(16))
  assert_true(known == @telnet.KnownOption::OutputLinefeedDisposition)
  assert_true(known.to_code() == opt(16))
}

///|
test "restored generated known option 17 maps to ExtendedAscii" {
  let known = @telnet.KnownOption::from_code(opt(17))
  assert_true(known == @telnet.KnownOption::ExtendedAscii)
  assert_true(known.to_code() == opt(17))
}

///|
test "restored generated known option 18 maps to Logout" {
  let known = @telnet.KnownOption::from_code(opt(18))
  assert_true(known == @telnet.KnownOption::Logout)
  assert_true(known.to_code() == opt(18))
}

///|
test "restored generated known option 19 maps to ByteMacro" {
  let known = @telnet.KnownOption::from_code(opt(19))
  assert_true(known == @telnet.KnownOption::ByteMacro)
  assert_true(known.to_code() == opt(19))
}

///|
test "restored generated known option 20 maps to DataEntryTerminal" {
  let known = @telnet.KnownOption::from_code(opt(20))
  assert_true(known == @telnet.KnownOption::DataEntryTerminal)
  assert_true(known.to_code() == opt(20))
}

///|
test "restored generated known option 21 maps to Supdup" {
  let known = @telnet.KnownOption::from_code(opt(21))
  assert_true(known == @telnet.KnownOption::Supdup)
  assert_true(known.to_code() == opt(21))
}

///|
test "restored generated known option 22 maps to SupdupOutput" {
  let known = @telnet.KnownOption::from_code(opt(22))
  assert_true(known == @telnet.KnownOption::SupdupOutput)
  assert_true(known.to_code() == opt(22))
}

///|
test "restored generated known option 23 maps to SendLocation" {
  let known = @telnet.KnownOption::from_code(opt(23))
  assert_true(known == @telnet.KnownOption::SendLocation)
  assert_true(known.to_code() == opt(23))
}

///|
test "restored generated known option 24 maps to TerminalType" {
  let known = @telnet.KnownOption::from_code(opt(24))
  assert_true(known == @telnet.KnownOption::TerminalType)
  assert_true(known.to_code() == opt(24))
}

///|
test "restored generated known option 25 maps to EndOfRecord" {
  let known = @telnet.KnownOption::from_code(opt(25))
  assert_true(known == @telnet.KnownOption::EndOfRecord)
  assert_true(known.to_code() == opt(25))
}

///|
test "restored generated known option 26 maps to TacacsUserIdentification" {
  let known = @telnet.KnownOption::from_code(opt(26))
  assert_true(known == @telnet.KnownOption::TacacsUserIdentification)
  assert_true(known.to_code() == opt(26))
}

///|
test "restored generated known option 27 maps to OutputMarking" {
  let known = @telnet.KnownOption::from_code(opt(27))
  assert_true(known == @telnet.KnownOption::OutputMarking)
  assert_true(known.to_code() == opt(27))
}

///|
test "restored generated known option 28 maps to TerminalLocationNumber" {
  let known = @telnet.KnownOption::from_code(opt(28))
  assert_true(known == @telnet.KnownOption::TerminalLocationNumber)
  assert_true(known.to_code() == opt(28))
}

///|
test "restored generated known option 29 maps to Telnet3270Regime" {
  let known = @telnet.KnownOption::from_code(opt(29))
  assert_true(known == @telnet.KnownOption::Telnet3270Regime)
  assert_true(known.to_code() == opt(29))
}

///|
test "restored generated known option 30 maps to X3Pad" {
  let known = @telnet.KnownOption::from_code(opt(30))
  assert_true(known == @telnet.KnownOption::X3Pad)
  assert_true(known.to_code() == opt(30))
}

///|
test "restored generated known option 31 maps to Naws" {
  let known = @telnet.KnownOption::from_code(opt(31))
  assert_true(known == @telnet.KnownOption::Naws)
  assert_true(known.to_code() == opt(31))
}

///|
test "restored generated known option 32 maps to TerminalSpeed" {
  let known = @telnet.KnownOption::from_code(opt(32))
  assert_true(known == @telnet.KnownOption::TerminalSpeed)
  assert_true(known.to_code() == opt(32))
}

///|
test "restored generated known option 33 maps to RemoteFlowControl" {
  let known = @telnet.KnownOption::from_code(opt(33))
  assert_true(known == @telnet.KnownOption::RemoteFlowControl)
  assert_true(known.to_code() == opt(33))
}

///|
test "restored generated known option 34 maps to Linemode" {
  let known = @telnet.KnownOption::from_code(opt(34))
  assert_true(known == @telnet.KnownOption::Linemode)
  assert_true(known.to_code() == opt(34))
}

///|
test "restored generated known option 35 maps to XDisplayLocation" {
  let known = @telnet.KnownOption::from_code(opt(35))
  assert_true(known == @telnet.KnownOption::XDisplayLocation)
  assert_true(known.to_code() == opt(35))
}

///|
test "restored generated known option 36 maps to Environment" {
  let known = @telnet.KnownOption::from_code(opt(36))
  assert_true(known == @telnet.KnownOption::Environment)
  assert_true(known.to_code() == opt(36))
}

///|
test "restored generated known option 37 maps to Authentication" {
  let known = @telnet.KnownOption::from_code(opt(37))
  assert_true(known == @telnet.KnownOption::Authentication)
  assert_true(known.to_code() == opt(37))
}

///|
test "restored generated known option 38 maps to Encryption" {
  let known = @telnet.KnownOption::from_code(opt(38))
  assert_true(known == @telnet.KnownOption::Encryption)
  assert_true(known.to_code() == opt(38))
}

///|
test "restored generated known option 39 maps to NewEnvironment" {
  let known = @telnet.KnownOption::from_code(opt(39))
  assert_true(known == @telnet.KnownOption::NewEnvironment)
  assert_true(known.to_code() == opt(39))
}

///|
test "restored generated known option 40 maps to Tn3270e" {
  let known = @telnet.KnownOption::from_code(opt(40))
  assert_true(known == @telnet.KnownOption::Tn3270e)
  assert_true(known.to_code() == opt(40))
}

///|
test "restored generated known option 41 maps to Xauth" {
  let known = @telnet.KnownOption::from_code(opt(41))
  assert_true(known == @telnet.KnownOption::Xauth)
  assert_true(known.to_code() == opt(41))
}

///|
test "restored generated known option 42 maps to Charset" {
  let known = @telnet.KnownOption::from_code(opt(42))
  assert_true(known == @telnet.KnownOption::Charset)
  assert_true(known.to_code() == opt(42))
}

///|
test "restored generated known option 43 maps to TelnetRemoteSerialPort" {
  let known = @telnet.KnownOption::from_code(opt(43))
  assert_true(known == @telnet.KnownOption::TelnetRemoteSerialPort)
  assert_true(known.to_code() == opt(43))
}

///|
test "restored generated known option 44 maps to ComPortControl" {
  let known = @telnet.KnownOption::from_code(opt(44))
  assert_true(known == @telnet.KnownOption::ComPortControl)
  assert_true(known.to_code() == opt(44))
}

///|
test "restored generated known option 45 maps to TelnetSuppressLocalEcho" {
  let known = @telnet.KnownOption::from_code(opt(45))
  assert_true(known == @telnet.KnownOption::TelnetSuppressLocalEcho)
  assert_true(known.to_code() == opt(45))
}

///|
test "restored generated known option 46 maps to TelnetStartTls" {
  let known = @telnet.KnownOption::from_code(opt(46))
  assert_true(known == @telnet.KnownOption::TelnetStartTls)
  assert_true(known.to_code() == opt(46))
}

///|
test "restored generated known option 47 maps to Kermit" {
  let known = @telnet.KnownOption::from_code(opt(47))
  assert_true(known == @telnet.KnownOption::Kermit)
  assert_true(known.to_code() == opt(47))
}

///|
test "restored generated known option 48 maps to SendUrl" {
  let known = @telnet.KnownOption::from_code(opt(48))
  assert_true(known == @telnet.KnownOption::SendUrl)
  assert_true(known.to_code() == opt(48))
}

///|
test "restored generated known option 49 maps to ForwardX" {
  let known = @telnet.KnownOption::from_code(opt(49))
  assert_true(known == @telnet.KnownOption::ForwardX)
  assert_true(known.to_code() == opt(49))
}

///|
test "restored generated known option 255 maps to ExtendedOptionsList" {
  let known = @telnet.KnownOption::from_code(opt(255))
  assert_true(known == @telnet.KnownOption::ExtendedOptionsList)
  assert_true(known.to_code() == opt(255))
}

///|
test "restored generated unknown option 50 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(50))
  assert_true(known == @telnet.KnownOption::Unknown(opt(50)))
  assert_true(known.to_code() == opt(50))
}

///|
test "restored generated unknown option 51 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(51))
  assert_true(known == @telnet.KnownOption::Unknown(opt(51)))
  assert_true(known.to_code() == opt(51))
}

///|
test "restored generated unknown option 52 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(52))
  assert_true(known == @telnet.KnownOption::Unknown(opt(52)))
  assert_true(known.to_code() == opt(52))
}

///|
test "restored generated unknown option 53 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(53))
  assert_true(known == @telnet.KnownOption::Unknown(opt(53)))
  assert_true(known.to_code() == opt(53))
}

///|
test "restored generated unknown option 54 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(54))
  assert_true(known == @telnet.KnownOption::Unknown(opt(54)))
  assert_true(known.to_code() == opt(54))
}

///|
test "restored generated unknown option 55 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(55))
  assert_true(known == @telnet.KnownOption::Unknown(opt(55)))
  assert_true(known.to_code() == opt(55))
}

///|
test "restored generated unknown option 56 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(56))
  assert_true(known == @telnet.KnownOption::Unknown(opt(56)))
  assert_true(known.to_code() == opt(56))
}

///|
test "restored generated unknown option 57 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(57))
  assert_true(known == @telnet.KnownOption::Unknown(opt(57)))
  assert_true(known.to_code() == opt(57))
}

///|
test "restored generated unknown option 58 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(58))
  assert_true(known == @telnet.KnownOption::Unknown(opt(58)))
  assert_true(known.to_code() == opt(58))
}

///|
test "restored generated unknown option 59 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(59))
  assert_true(known == @telnet.KnownOption::Unknown(opt(59)))
  assert_true(known.to_code() == opt(59))
}

///|
test "restored generated unknown option 60 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(60))
  assert_true(known == @telnet.KnownOption::Unknown(opt(60)))
  assert_true(known.to_code() == opt(60))
}

///|
test "restored generated unknown option 93 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(93))
  assert_true(known == @telnet.KnownOption::Unknown(opt(93)))
  assert_true(known.to_code() == opt(93))
}

///|
test "restored generated unknown option 128 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(128))
  assert_true(known == @telnet.KnownOption::Unknown(opt(128)))
  assert_true(known.to_code() == opt(128))
}

///|
test "restored generated unknown option 200 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(200))
  assert_true(known == @telnet.KnownOption::Unknown(opt(200)))
  assert_true(known.to_code() == opt(200))
}

///|
test "restored generated unknown option 254 remains lossless" {
  let known = @telnet.KnownOption::from_code(opt(254))
  assert_true(known == @telnet.KnownOption::Unknown(opt(254)))
  assert_true(known.to_code() == opt(254))
}

///|
test "restored generated parser accepts WILL option 0" {
  restored_gen_assert_parse([255, 251, 0], [
    neg(@telnet.NegotiationVerb::Will, 0),
  ])
}

///|
test "restored generated parser accepts WILL option 1" {
  restored_gen_assert_parse([255, 251, 1], [
    neg(@telnet.NegotiationVerb::Will, 1),
  ])
}

///|
test "restored generated parser accepts WILL option 2" {
  restored_gen_assert_parse([255, 251, 2], [
    neg(@telnet.NegotiationVerb::Will, 2),
  ])
}

///|
test "restored generated parser accepts WILL option 3" {
  restored_gen_assert_parse([255, 251, 3], [
    neg(@telnet.NegotiationVerb::Will, 3),
  ])
}

///|
test "restored generated parser accepts WILL option 4" {
  restored_gen_assert_parse([255, 251, 4], [
    neg(@telnet.NegotiationVerb::Will, 4),
  ])
}

///|
test "restored generated parser accepts WILL option 5" {
  restored_gen_assert_parse([255, 251, 5], [
    neg(@telnet.NegotiationVerb::Will, 5),
  ])
}

///|
test "restored generated parser accepts WILL option 6" {
  restored_gen_assert_parse([255, 251, 6], [
    neg(@telnet.NegotiationVerb::Will, 6),
  ])
}

///|
test "restored generated parser accepts WILL option 7" {
  restored_gen_assert_parse([255, 251, 7], [
    neg(@telnet.NegotiationVerb::Will, 7),
  ])
}

///|
test "restored generated parser accepts WILL option 8" {
  restored_gen_assert_parse([255, 251, 8], [
    neg(@telnet.NegotiationVerb::Will, 8),
  ])
}

///|
test "restored generated parser accepts WILL option 9" {
  restored_gen_assert_parse([255, 251, 9], [
    neg(@telnet.NegotiationVerb::Will, 9),
  ])
}

///|
test "restored generated parser accepts WILL option 10" {
  restored_gen_assert_parse([255, 251, 10], [
    neg(@telnet.NegotiationVerb::Will, 10),
  ])
}

///|
test "restored generated parser accepts WILL option 11" {
  restored_gen_assert_parse([255, 251, 11], [
    neg(@telnet.NegotiationVerb::Will, 11),
  ])
}

///|
test "restored generated parser accepts WILL option 12" {
  restored_gen_assert_parse([255, 251, 12], [
    neg(@telnet.NegotiationVerb::Will, 12),
  ])
}

///|
test "restored generated parser accepts WILL option 13" {
  restored_gen_assert_parse([255, 251, 13], [
    neg(@telnet.NegotiationVerb::Will, 13),
  ])
}

///|
test "restored generated parser accepts WILL option 14" {
  restored_gen_assert_parse([255, 251, 14], [
    neg(@telnet.NegotiationVerb::Will, 14),
  ])
}

///|
test "restored generated parser accepts WILL option 15" {
  restored_gen_assert_parse([255, 251, 15], [
    neg(@telnet.NegotiationVerb::Will, 15),
  ])
}

///|
test "restored generated parser accepts WILL option 16" {
  restored_gen_assert_parse([255, 251, 16], [
    neg(@telnet.NegotiationVerb::Will, 16),
  ])
}

///|
test "restored generated parser accepts WILL option 17" {
  restored_gen_assert_parse([255, 251, 17], [
    neg(@telnet.NegotiationVerb::Will, 17),
  ])
}

///|
test "restored generated parser accepts WILL option 18" {
  restored_gen_assert_parse([255, 251, 18], [
    neg(@telnet.NegotiationVerb::Will, 18),
  ])
}

///|
test "restored generated parser accepts WILL option 19" {
  restored_gen_assert_parse([255, 251, 19], [
    neg(@telnet.NegotiationVerb::Will, 19),
  ])
}

///|
test "restored generated parser accepts WILL option 20" {
  restored_gen_assert_parse([255, 251, 20], [
    neg(@telnet.NegotiationVerb::Will, 20),
  ])
}

///|
test "restored generated parser accepts WILL option 21" {
  restored_gen_assert_parse([255, 251, 21], [
    neg(@telnet.NegotiationVerb::Will, 21),
  ])
}

///|
test "restored generated parser accepts WILL option 22" {
  restored_gen_assert_parse([255, 251, 22], [
    neg(@telnet.NegotiationVerb::Will, 22),
  ])
}

///|
test "restored generated parser accepts WILL option 23" {
  restored_gen_assert_parse([255, 251, 23], [
    neg(@telnet.NegotiationVerb::Will, 23),
  ])
}

///|
test "restored generated parser accepts WILL option 24" {
  restored_gen_assert_parse([255, 251, 24], [
    neg(@telnet.NegotiationVerb::Will, 24),
  ])
}

///|
test "restored generated parser accepts WILL option 25" {
  restored_gen_assert_parse([255, 251, 25], [
    neg(@telnet.NegotiationVerb::Will, 25),
  ])
}

///|
test "restored generated parser accepts WILL option 26" {
  restored_gen_assert_parse([255, 251, 26], [
    neg(@telnet.NegotiationVerb::Will, 26),
  ])
}

///|
test "restored generated parser accepts WILL option 27" {
  restored_gen_assert_parse([255, 251, 27], [
    neg(@telnet.NegotiationVerb::Will, 27),
  ])
}

///|
test "restored generated parser accepts WILL option 28" {
  restored_gen_assert_parse([255, 251, 28], [
    neg(@telnet.NegotiationVerb::Will, 28),
  ])
}

///|
test "restored generated parser accepts WILL option 29" {
  restored_gen_assert_parse([255, 251, 29], [
    neg(@telnet.NegotiationVerb::Will, 29),
  ])
}

///|
test "restored generated parser accepts WILL option 30" {
  restored_gen_assert_parse([255, 251, 30], [
    neg(@telnet.NegotiationVerb::Will, 30),
  ])
}

///|
test "restored generated parser accepts WILL option 31" {
  restored_gen_assert_parse([255, 251, 31], [
    neg(@telnet.NegotiationVerb::Will, 31),
  ])
}

///|
test "restored generated parser accepts WILL option 32" {
  restored_gen_assert_parse([255, 251, 32], [
    neg(@telnet.NegotiationVerb::Will, 32),
  ])
}

///|
test "restored generated parser accepts WILL option 33" {
  restored_gen_assert_parse([255, 251, 33], [
    neg(@telnet.NegotiationVerb::Will, 33),
  ])
}

///|
test "restored generated parser accepts WILL option 34" {
  restored_gen_assert_parse([255, 251, 34], [
    neg(@telnet.NegotiationVerb::Will, 34),
  ])
}

///|
test "restored generated parser accepts WILL option 35" {
  restored_gen_assert_parse([255, 251, 35], [
    neg(@telnet.NegotiationVerb::Will, 35),
  ])
}

///|
test "restored generated parser accepts WILL option 36" {
  restored_gen_assert_parse([255, 251, 36], [
    neg(@telnet.NegotiationVerb::Will, 36),
  ])
}

///|
test "restored generated parser accepts WILL option 37" {
  restored_gen_assert_parse([255, 251, 37], [
    neg(@telnet.NegotiationVerb::Will, 37),
  ])
}

///|
test "restored generated parser accepts WILL option 38" {
  restored_gen_assert_parse([255, 251, 38], [
    neg(@telnet.NegotiationVerb::Will, 38),
  ])
}

///|
test "restored generated parser accepts WILL option 39" {
  restored_gen_assert_parse([255, 251, 39], [
    neg(@telnet.NegotiationVerb::Will, 39),
  ])
}

///|
test "restored generated parser accepts WILL option 40" {
  restored_gen_assert_parse([255, 251, 40], [
    neg(@telnet.NegotiationVerb::Will, 40),
  ])
}

///|
test "restored generated parser accepts WILL option 41" {
  restored_gen_assert_parse([255, 251, 41], [
    neg(@telnet.NegotiationVerb::Will, 41),
  ])
}

///|
test "restored generated parser accepts WILL option 42" {
  restored_gen_assert_parse([255, 251, 42], [
    neg(@telnet.NegotiationVerb::Will, 42),
  ])
}

///|
test "restored generated parser accepts WILL option 43" {
  restored_gen_assert_parse([255, 251, 43], [
    neg(@telnet.NegotiationVerb::Will, 43),
  ])
}

///|
test "restored generated parser accepts WILL option 44" {
  restored_gen_assert_parse([255, 251, 44], [
    neg(@telnet.NegotiationVerb::Will, 44),
  ])
}

///|
test "restored generated parser accepts WILL option 45" {
  restored_gen_assert_parse([255, 251, 45], [
    neg(@telnet.NegotiationVerb::Will, 45),
  ])
}

///|
test "restored generated parser accepts WILL option 46" {
  restored_gen_assert_parse([255, 251, 46], [
    neg(@telnet.NegotiationVerb::Will, 46),
  ])
}

///|
test "restored generated parser accepts WILL option 47" {
  restored_gen_assert_parse([255, 251, 47], [
    neg(@telnet.NegotiationVerb::Will, 47),
  ])
}

///|
test "restored generated parser accepts WILL option 48" {
  restored_gen_assert_parse([255, 251, 48], [
    neg(@telnet.NegotiationVerb::Will, 48),
  ])
}

///|
test "restored generated parser accepts WILL option 49" {
  restored_gen_assert_parse([255, 251, 49], [
    neg(@telnet.NegotiationVerb::Will, 49),
  ])
}

///|
test "restored generated encoder writes DO for option 0" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 0)),
    [255, 253, 0],
  )
}

///|
test "restored generated encoder writes DO for option 1" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 1)),
    [255, 253, 1],
  )
}

///|
test "restored generated encoder writes DO for option 3" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 3)),
    [255, 253, 3],
  )
}

///|
test "restored generated encoder writes DO for option 24" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 24)),
    [255, 253, 24],
  )
}

///|
test "restored generated encoder writes DO for option 31" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 31)),
    [255, 253, 31],
  )
}

///|
test "restored generated encoder writes DO for option 34" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 34)),
    [255, 253, 34],
  )
}

///|
test "restored generated encoder writes DO for option 37" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 37)),
    [255, 253, 37],
  )
}

///|
test "restored generated encoder writes DO for option 38" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 38)),
    [255, 253, 38],
  )
}

///|
test "restored generated encoder writes DO for option 39" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 39)),
    [255, 253, 39],
  )
}

///|
test "restored generated encoder writes DO for option 42" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 42)),
    [255, 253, 42],
  )
}

///|
test "restored generated encoder writes DO for option 46" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 46)),
    [255, 253, 46],
  )
}

///|
test "restored generated encoder writes DO for option 93" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 93)),
    [255, 253, 93],
  )
}

///|
test "restored generated encoder writes DO for option 255" {
  restored_gen_assert_encoded(
    @telnet.EncodeItem::Negotiation(neg_event(@telnet.NegotiationVerb::Do, 255)),
    [255, 253, 255],
  )
}

///|
test "restored generated raw subnegotiation option 50 preserves payload" {
  let wire = [255, 250, 50, 65, 255, 255, 66, 255, 240]
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.events == [sb(50, [65, 255, 66])])
  match result.events[0] {
    @telnet.Event::Subnegotiation(s) => {
      assert_true(s.option == opt(50))
      assert_true(s.payload.to_bytes() == bytes([65, 255, 66]))
      restored_gen_assert_decode(
        50,
        [65, 255, 66],
        @telnet.OptionPayload::Raw(opt(50), span([65, 255, 66])),
      )
    }
    _ => assert_true(false)
  }
}

///|
test "restored generated raw subnegotiation option 93 preserves payload" {
  let wire = [255, 250, 93, 65, 255, 255, 66, 255, 240]
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.events == [sb(93, [65, 255, 66])])
  match result.events[0] {
    @telnet.Event::Subnegotiation(s) => {
      assert_true(s.option == opt(93))
      assert_true(s.payload.to_bytes() == bytes([65, 255, 66]))
      restored_gen_assert_decode(
        93,
        [65, 255, 66],
        @telnet.OptionPayload::Raw(opt(93), span([65, 255, 66])),
      )
    }
    _ => assert_true(false)
  }
}

///|
test "restored generated raw subnegotiation option 128 preserves payload" {
  let wire = [255, 250, 128, 65, 255, 255, 66, 255, 240]
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.events == [sb(128, [65, 255, 66])])
  match result.events[0] {
    @telnet.Event::Subnegotiation(s) => {
      assert_true(s.option == opt(128))
      assert_true(s.payload.to_bytes() == bytes([65, 255, 66]))
      restored_gen_assert_decode(
        128,
        [65, 255, 66],
        @telnet.OptionPayload::Raw(opt(128), span([65, 255, 66])),
      )
    }
    _ => assert_true(false)
  }
}

///|
test "restored generated raw subnegotiation option 200 preserves payload" {
  let wire = [255, 250, 200, 65, 255, 255, 66, 255, 240]
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.events == [sb(200, [65, 255, 66])])
  match result.events[0] {
    @telnet.Event::Subnegotiation(s) => {
      assert_true(s.option == opt(200))
      assert_true(s.payload.to_bytes() == bytes([65, 255, 66]))
      restored_gen_assert_decode(
        200,
        [65, 255, 66],
        @telnet.OptionPayload::Raw(opt(200), span([65, 255, 66])),
      )
    }
    _ => assert_true(false)
  }
}

///|
test "restored generated raw subnegotiation option 254 preserves payload" {
  let wire = [255, 250, 254, 65, 255, 255, 66, 255, 240]
  let result = @telnet.Parser::default().feed(bytes(wire))
  assert_true(result.events == [sb(254, [65, 255, 66])])
  match result.events[0] {
    @telnet.Event::Subnegotiation(s) => {
      assert_true(s.option == opt(254))
      assert_true(s.payload.to_bytes() == bytes([65, 255, 66]))
      restored_gen_assert_decode(
        254,
        [65, 255, 66],
        @telnet.OptionPayload::Raw(opt(254), span([65, 255, 66])),
      )
    }
    _ => assert_true(false)
  }
}

///|
test "restored generated NAWS decodes 0x0" {
  restored_gen_assert_decode(
    31,
    [0, 0, 0, 0],
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (0).to_uint16(),
      rows: (0).to_uint16(),
    }),
  )
}

///|
test "restored generated NAWS decodes 1x1" {
  restored_gen_assert_decode(
    31,
    [0, 1, 0, 1],
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (1).to_uint16(),
      rows: (1).to_uint16(),
    }),
  )
}

///|
test "restored generated NAWS decodes 80x24" {
  restored_gen_assert_decode(
    31,
    [0, 80, 0, 24],
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (80).to_uint16(),
      rows: (24).to_uint16(),
    }),
  )
}

///|
test "restored generated NAWS decodes 132x43" {
  restored_gen_assert_decode(
    31,
    [0, 132, 0, 43],
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (132).to_uint16(),
      rows: (43).to_uint16(),
    }),
  )
}

///|
test "restored generated NAWS decodes 255x255" {
  restored_gen_assert_decode(
    31,
    [0, 255, 0, 255],
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (255).to_uint16(),
      rows: (255).to_uint16(),
    }),
  )
}

///|
test "restored generated NAWS decodes 256x512" {
  restored_gen_assert_decode(
    31,
    [1, 0, 2, 0],
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (256).to_uint16(),
      rows: (512).to_uint16(),
    }),
  )
}

///|
test "restored generated NAWS decodes 65535x65535" {
  restored_gen_assert_decode(
    31,
    [255, 255, 255, 255],
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (65535).to_uint16(),
      rows: (65535).to_uint16(),
    }),
  )
}

///|
test "restored generated LINEMODE MODE decodes edit" {
  restored_gen_assert_decode(
    34,
    [1, 1],
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
        flags: [@telnet.LinemodeModeFlag::Edit],
      }),
    ),
  )
}

///|
test "restored generated LINEMODE MODE decodes trapsig" {
  restored_gen_assert_decode(
    34,
    [1, 2],
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
        flags: [@telnet.LinemodeModeFlag::TrapSig],
      }),
    ),
  )
}

///|
test "restored generated LINEMODE MODE decodes edit_trapsig" {
  restored_gen_assert_decode(
    34,
    [1, 3],
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
        flags: [
          @telnet.LinemodeModeFlag::Edit,
          @telnet.LinemodeModeFlag::TrapSig,
        ],
      }),
    ),
  )
}

///|
test "restored generated LINEMODE MODE decodes ack" {
  restored_gen_assert_decode(
    34,
    [1, 4],
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
        flags: [@telnet.LinemodeModeFlag::ModeAck],
      }),
    ),
  )
}

///|
test "restored generated LINEMODE MODE decodes soft_tab" {
  restored_gen_assert_decode(
    34,
    [1, 8],
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
        flags: [@telnet.LinemodeModeFlag::SoftTab],
      }),
    ),
  )
}

///|
test "restored generated LINEMODE MODE decodes lit_echo" {
  restored_gen_assert_decode(
    34,
    [1, 16],
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
        flags: [@telnet.LinemodeModeFlag::LitEcho],
      }),
    ),
  )
}

///|
test "restored generated CHARSET TTABLE-IS decodes table name" {
  restored_gen_assert_decode(
    42,
    [4, 108, 97, 116, 105, 110, 49],
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableIs("latin1")),
  )
}

///|
test "restored generated CHARSET TTABLE-REJECTED decodes" {
  restored_gen_assert_decode(
    42,
    [5],
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableRejected),
  )
}

///|
test "restored generated CHARSET TTABLE-ACK decodes" {
  restored_gen_assert_decode(
    42,
    [6],
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableAck),
  )
}

///|
test "restored generated CHARSET TTABLE-NAK decodes" {
  restored_gen_assert_decode(
    42,
    [7],
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableNak),
  )
}

///|
test "restored generated START_TLS START decodes and encodes" {
  restored_gen_assert_decode(
    46,
    [0],
    @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::StartTls),
  )
  let out = Bytes::new(1)
  match
    @telnet.OptionPayload::encode(
      @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::StartTls),
      out,
    ) {
    Ok(r) => {
      assert_true(r.bytes_written == 1)
      assert_true(out == bytes([0]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "restored generated START_TLS FOLLOWS decodes and encodes" {
  restored_gen_assert_decode(
    46,
    [1],
    @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows),
  )
  let out = Bytes::new(1)
  match
    @telnet.OptionPayload::encode(
      @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows),
      out,
    ) {
    Ok(r) => {
      assert_true(r.bytes_written == 1)
      assert_true(out == bytes([1]))
    }
    Err(_) => assert_true(false)
  }
}
