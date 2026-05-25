// Malformed option codec matrices. These lock down negative codec behavior across
// edge payloads without changing production code.

///|
fn malformed_expect_error(
  option : Int,
  payload : Array[Int],
  kind : @telnet.TelnetErrorKind,
) -> Unit raise {
  match @telnet.OptionPayload::decode(opt(option), span(payload)) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == kind)
      match e.option {
        Some(actual) => assert_true(actual == opt(option))
        None => ()
      }
    }
  }
}

///|
fn malformed_expect_error_at(
  option : Int,
  payload : Array[Int],
  kind : @telnet.TelnetErrorKind,
  offset : Int,
  expected_byte : Int,
  error_option : Int,
) -> Unit raise {
  match @telnet.OptionPayload::decode(opt(option), span(payload)) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == kind)
      if offset >= 0 {
        assert_true(e.offset == offset)
      }
      if expected_byte >= 0 {
        assert_true(e.byte == Some(byte(expected_byte)))
      } else {
        assert_true(e.byte == None)
      }
      if error_option >= 0 {
        assert_true(e.option == Some(opt(error_option)))
      } else {
        assert_true(e.option == None)
      }
    }
  }
}

///|
test "malformed TERMINAL-TYPE subcommands and strings reject" {
  let invalid = [2, 3, 42, 254, 255]
  invalid.each(fn(n) raise {
    malformed_expect_error(24, [n], @telnet.TelnetErrorKind::InvalidOptionByte)
  })
  malformed_expect_error(
    24,
    [],
    @telnet.TelnetErrorKind::IncompleteSubnegotiation,
  )
  malformed_expect_error(24, [0], @telnet.TelnetErrorKind::PolicyRejected)
  malformed_expect_error(
    24,
    [0, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
  )
  malformed_expect_error(
    24,
    [0, 255],
    @telnet.TelnetErrorKind::InvalidOptionByte,
  )
}

///|
test "malformed NAWS lengths reject except exact four bytes" {
  for len = 0; len <= 10; len = len + 1 {
    if len != 4 {
      malformed_expect_error(
        31,
        Array::make(len, 0),
        @telnet.TelnetErrorKind::IncompleteSubnegotiation,
      )
    }
  }
  match @telnet.OptionPayload::decode(opt(31), span([0, 0, 0, 0])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Naws(@telnet.NawsSize::{
          columns: (0).to_uint16(),
          rows: (0).to_uint16(),
        }),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "malformed NEW-ENVIRON commands markers escapes and high bytes reject" {
  malformed_expect_error(
    39,
    [],
    @telnet.TelnetErrorKind::IncompleteSubnegotiation,
  )
  malformed_expect_error(39, [9], @telnet.TelnetErrorKind::InvalidCommandByte)
  malformed_expect_error(39, [0, 2], @telnet.TelnetErrorKind::InvalidOptionByte)
  malformed_expect_error(
    39,
    [0, 0, 65, 1, 2],
    @telnet.TelnetErrorKind::IncompleteSubnegotiation,
  )
  malformed_expect_error(
    39,
    [0, 0, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
  )
  malformed_expect_error(
    39,
    [0, 0, 65, 1, 255],
    @telnet.TelnetErrorKind::InvalidOptionByte,
  )
}

///|
test "malformed CHARSET requests accepted and ttable variants reject precisely" {
  malformed_expect_error(
    42,
    [],
    @telnet.TelnetErrorKind::IncompleteSubnegotiation,
  )
  malformed_expect_error(42, [1], @telnet.TelnetErrorKind::PolicyRejected)
  malformed_expect_error(42, [1, 32], @telnet.TelnetErrorKind::PolicyRejected)
  malformed_expect_error(
    42,
    [1, 32, 32],
    @telnet.TelnetErrorKind::PolicyRejected,
  )
  malformed_expect_error(
    42,
    [1, 32, 85, 32],
    @telnet.TelnetErrorKind::PolicyRejected,
  )
  malformed_expect_error(
    42,
    [1, 32, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
  )
  malformed_expect_error(42, [2], @telnet.TelnetErrorKind::PolicyRejected)
  malformed_expect_error(
    42,
    [2, 255],
    @telnet.TelnetErrorKind::InvalidOptionByte,
  )
  malformed_expect_error(42, [4], @telnet.TelnetErrorKind::PolicyRejected)
  malformed_expect_error(
    42,
    [4, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
  )
  malformed_expect_error(42, [8], @telnet.TelnetErrorKind::InvalidCommandByte)
  malformed_expect_error(42, [99], @telnet.TelnetErrorKind::InvalidCommandByte)
}

///|
test "malformed codec encoders report short output capacity" {
  match
    @telnet.TerminalTypeMessage::encode(
      @telnet.TerminalTypeMessage::Send,
      Bytes::new(0),
    ) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      assert_true(e.required_capacity == 1)
    }
  }
  match
    @telnet.EnvironmentMessage::encode(
      @telnet.EnvironmentMessage::Send(["TERM"]),
      Bytes::new(1),
    ) {
    Ok(_) => assert_true(false)
    Err(e) => {
      assert_true(e.kind == @telnet.EncodeErrorKind::OutputBufferTooSmall)
      assert_true(e.required_capacity == 6)
    }
  }
}

///|
test "malformed NEW-ENVIRON dangling escaped name rejects precisely" {
  malformed_expect_error_at(
    39,
    [0, 0, 65, 2],
    @telnet.TelnetErrorKind::IncompleteSubnegotiation,
    3,
    2,
    39,
  )
}

///|
test "malformed LINEMODE empty and unknown commands reject" {
  malformed_expect_error(34, [], @telnet.TelnetErrorKind::InvalidCommandByte)
  malformed_expect_error(34, [0], @telnet.TelnetErrorKind::InvalidCommandByte)
  malformed_expect_error(34, [1], @telnet.TelnetErrorKind::InvalidCommandByte)
  malformed_expect_error(34, [4], @telnet.TelnetErrorKind::InvalidCommandByte)
  malformed_expect_error(
    34,
    [99, 1, 2],
    @telnet.TelnetErrorKind::InvalidCommandByte,
  )
}

///|
test "malformed codec ASCII and high-byte metadata matrix rejects" {
  malformed_expect_error_at(
    24,
    [0, 31, 32, 126, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
    4,
    128,
    -1,
  )
  malformed_expect_error_at(
    24,
    [0, 86, 84, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
    3,
    128,
    -1,
  )
  malformed_expect_error_at(
    24,
    [0],
    @telnet.TelnetErrorKind::PolicyRejected,
    0,
    0,
    24,
  )
  malformed_expect_error_at(
    42,
    [1, 32, 85, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
    3,
    128,
    -1,
  )
  malformed_expect_error_at(
    42,
    [1, 32, 32],
    @telnet.TelnetErrorKind::PolicyRejected,
    2,
    32,
    42,
  )
  malformed_expect_error_at(
    42,
    [2, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
    1,
    128,
    -1,
  )
  malformed_expect_error_at(
    42,
    [2],
    @telnet.TelnetErrorKind::PolicyRejected,
    0,
    2,
    42,
  )
  malformed_expect_error_at(
    42,
    [4, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
    1,
    128,
    -1,
  )
  malformed_expect_error_at(
    42,
    [4],
    @telnet.TelnetErrorKind::PolicyRejected,
    0,
    4,
    42,
  )
  malformed_expect_error_at(
    39,
    [0, 0, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
    2,
    128,
    39,
  )
  malformed_expect_error_at(
    39,
    [0, 0, 65, 1, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
    4,
    128,
    39,
  )
  malformed_expect_error_at(
    39,
    [0, 0, 65, 1, 2, 128],
    @telnet.TelnetErrorKind::InvalidOptionByte,
    5,
    128,
    39,
  )
}

///|
test "codec matrix accepts boundary ASCII and current empty environment fields" {
  match @telnet.OptionPayload::decode(opt(24), span([0, 31, 32, 126, 127])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::TerminalType(
          @telnet.TerminalTypeMessage::Is("\u001f ~\u007f"),
        ),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.OptionPayload::decode(opt(42), span([2, 31, 32, 126, 127])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Charset(
          @telnet.CharsetMessage::Accepted("\u001f ~\u007f"),
        ),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.OptionPayload::decode(opt(39), span([0, 0, 1, 3])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Environment(
          @telnet.EnvironmentMessage::Is([
            @telnet.EnvironmentVariable::{
              kind: @telnet.EnvironmentVariableKind::Var,
              name: "",
              value: Some(""),
            },
            @telnet.EnvironmentVariable::{
              kind: @telnet.EnvironmentVariableKind::UserVar,
              name: "",
              value: None,
            },
          ]),
        ),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.OptionPayload::decode(opt(39), span([1, 0])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Environment(
          @telnet.EnvironmentMessage::Send([""]),
        ),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "LINEMODE raw spans preserve high bytes" {
  match @telnet.OptionPayload::decode(opt(34), span([2, 128, 254, 255])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Linemode(
          @telnet.LinemodeMessage::ForwardMask(
            @telnet.LinemodeForwardMask::Bytes(span([128, 254, 255])),
          ),
        ),
      )
    Err(_) => assert_true(false)
  }
  match @telnet.OptionPayload::decode(opt(34), span([3, 0, 128, 255])) {
    Ok(payload) =>
      assert_true(
        payload ==
        @telnet.OptionPayload::Linemode(
          @telnet.LinemodeMessage::Slc(span([0, 128, 255])),
        ),
      )
    Err(_) => assert_true(false)
  }
}

///|
test "malformed START_TLS length and subcommand matrix rejects" {
  malformed_expect_error(46, [], @telnet.TelnetErrorKind::PolicyRejected)
  malformed_expect_error(46, [0, 0], @telnet.TelnetErrorKind::PolicyRejected)
  malformed_expect_error(46, [1, 0], @telnet.TelnetErrorKind::PolicyRejected)
  let invalid = [2, 3, 42, 128, 255]
  invalid.each(fn(n) raise {
    malformed_expect_error(46, [n], @telnet.TelnetErrorKind::InvalidOptionByte)
  })
}
