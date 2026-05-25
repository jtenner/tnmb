// Option codec roundtrip matrices for encode/decode behavior not fully covered by
// parser-centric tests.

///|
fn codec_assert_roundtrip(
  option : Int,
  payload : @telnet.OptionPayload,
) -> Unit raise {
  let required = @telnet.OptionPayload::required_capacity(payload)
  let out = Bytes::new(required)
  match @telnet.OptionPayload::encode(payload, out) {
    Ok(r) => {
      assert_true(r.bytes_written == required)
      match
        @telnet.OptionPayload::decode(opt(option), @telnet.ByteSpan::{
          bytes: out,
          start: 0,
          length: r.bytes_written,
        }) {
        Ok(decoded) => assert_true(decoded == payload)
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
fn codec_assert_decode_encode(
  option : Int,
  wire : Array[Int],
  expected : @telnet.OptionPayload,
  canonical : Array[Int],
) -> Unit raise {
  match @telnet.OptionPayload::decode(opt(option), span(wire)) {
    Ok(decoded) => {
      assert_true(decoded == expected)
      let out = Bytes::new(@telnet.OptionPayload::required_capacity(decoded))
      match @telnet.OptionPayload::encode(decoded, out) {
        Ok(r) => {
          assert_true(r.bytes_written == canonical.length())
          assert_true(out == bytes(canonical))
        }
        Err(_) => assert_true(false)
      }
    }
    Err(_) => assert_true(false)
  }
}

///|
test "codec matrix TERMINAL-TYPE roundtrips edge strings" {
  codec_assert_roundtrip(
    24,
    @telnet.OptionPayload::TerminalType(@telnet.TerminalTypeMessage::Send),
  )
  codec_assert_roundtrip(
    24,
    @telnet.OptionPayload::TerminalType(
      @telnet.TerminalTypeMessage::Is("VT100"),
    ),
  )
  codec_assert_roundtrip(
    24,
    @telnet.OptionPayload::TerminalType(
      @telnet.TerminalTypeMessage::Is("xterm-256color"),
    ),
  )
  codec_assert_roundtrip(
    24,
    @telnet.OptionPayload::TerminalType(
      @telnet.TerminalTypeMessage::Is("xterm\u0000raw"),
    ),
  )
}

///|
test "codec matrix NAWS boundary roundtrips" {
  codec_assert_roundtrip(
    31,
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (0).to_uint16(),
      rows: (0).to_uint16(),
    }),
  )
  codec_assert_roundtrip(
    31,
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (1).to_uint16(),
      rows: (1).to_uint16(),
    }),
  )
  codec_assert_roundtrip(
    31,
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (255).to_uint16(),
      rows: (255).to_uint16(),
    }),
  )
  codec_assert_roundtrip(
    31,
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (256).to_uint16(),
      rows: (512).to_uint16(),
    }),
  )
  codec_assert_roundtrip(
    31,
    @telnet.OptionPayload::Naws(@telnet.NawsSize::{
      columns: (65535).to_uint16(),
      rows: (65535).to_uint16(),
    }),
  )
}

///|
test "codec matrix NEW-ENVIRON roundtrips send is and info" {
  codec_assert_roundtrip(
    39,
    @telnet.OptionPayload::Environment(
      @telnet.EnvironmentMessage::Send(["TERM", "USER"]),
    ),
  )
  codec_assert_roundtrip(
    39,
    @telnet.OptionPayload::Environment(
      @telnet.EnvironmentMessage::Is([
        @telnet.EnvironmentVariable::{
          kind: @telnet.EnvironmentVariableKind::Var,
          name: "TERM",
          value: Some("xterm"),
        },
        @telnet.EnvironmentVariable::{
          kind: @telnet.EnvironmentVariableKind::UserVar,
          name: "USER",
          value: None,
        },
      ]),
    ),
  )
  codec_assert_roundtrip(
    39,
    @telnet.OptionPayload::Environment(
      @telnet.EnvironmentMessage::Info([
        @telnet.EnvironmentVariable::{
          kind: @telnet.EnvironmentVariableKind::Var,
          name: "A",
          value: Some("BC"),
        },
        @telnet.EnvironmentVariable::{
          kind: @telnet.EnvironmentVariableKind::Var,
          name: "D",
          value: Some(""),
        },
        @telnet.EnvironmentVariable::{
          kind: @telnet.EnvironmentVariableKind::Var,
          name: "E",
          value: None,
        },
      ]),
    ),
  )
}

///|
test "codec matrix CHARSET request accepted rejected and TTABLE variants roundtrip" {
  codec_assert_roundtrip(
    42,
    @telnet.OptionPayload::Charset(
      @telnet.CharsetMessage::Request(["UTF-8", "US-ASCII"]),
    ),
  )
  codec_assert_roundtrip(
    42,
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::Accepted("UTF-8")),
  )
  codec_assert_roundtrip(
    42,
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::Rejected),
  )
  codec_assert_roundtrip(
    42,
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableIs("latin1")),
  )
  codec_assert_roundtrip(
    42,
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableRejected),
  )
  codec_assert_roundtrip(
    42,
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableAck),
  )
  codec_assert_roundtrip(
    42,
    @telnet.OptionPayload::Charset(@telnet.CharsetMessage::TTableNak),
  )
}

///|
test "codec matrix empty CHARSET request encoding is current canonical shape" {
  let payload = @telnet.OptionPayload::Charset(
    @telnet.CharsetMessage::Request([]),
  )
  assert_true(@telnet.OptionPayload::required_capacity(payload) == 2)
  let out = Bytes::make(3, byte(88))
  match @telnet.OptionPayload::encode(payload, out) {
    Ok(r) => {
      assert_true(r.bytes_written == 2)
      assert_true(r.required_capacity == 2)
      assert_true(out == bytes([1, 32, 88]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "codec matrix OptionPayload Empty encodes to zero bytes" {
  let payload = @telnet.OptionPayload::Empty
  assert_true(@telnet.OptionPayload::required_capacity(payload) == 0)
  let out = Bytes::make(2, byte(88))
  match @telnet.OptionPayload::encode(payload, out) {
    Ok(r) => {
      assert_true(r.bytes_written == 0)
      assert_true(r.required_capacity == 0)
      assert_true(out == bytes([88, 88]))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "codec matrix LINEMODE modes forward masks and SLC roundtrip" {
  codec_assert_roundtrip(
    34,
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{ flags: [] }),
    ),
  )
  codec_assert_roundtrip(
    34,
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::Mode(@telnet.LinemodeMode::{
        flags: [
          @telnet.LinemodeModeFlag::Edit,
          @telnet.LinemodeModeFlag::TrapSig,
          @telnet.LinemodeModeFlag::ModeAck,
        ],
      }),
    ),
  )
  codec_assert_roundtrip(
    34,
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::ForwardMask(@telnet.LinemodeForwardMask::Default),
    ),
  )
  codec_assert_roundtrip(
    34,
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::ForwardMask(@telnet.LinemodeForwardMask::None),
    ),
  )
  codec_assert_roundtrip(
    34,
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::ForwardMask(
        @telnet.LinemodeForwardMask::Bytes(span([0, 1, 255])),
      ),
    ),
  )
  codec_assert_roundtrip(
    34,
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::Slc(span([1, 2, 3, 4, 5, 6])),
    ),
  )
}

///|
test "codec matrix START_TLS roundtrips both messages" {
  codec_assert_roundtrip(
    46,
    @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::StartTls),
  )
  codec_assert_roundtrip(
    46,
    @telnet.OptionPayload::StartTls(@telnet.StartTlsMessage::Follows),
  )
}

///|
test "codec matrix decode encode canonical wire samples" {
  codec_assert_decode_encode(
    42,
    [1, 59, 85, 84, 70, 45, 56, 59, 85, 83, 45, 65, 83, 67, 73, 73],
    @telnet.OptionPayload::Charset(
      @telnet.CharsetMessage::Request(["UTF-8", "US-ASCII"]),
    ),
    [1, 32, 85, 84, 70, 45, 56, 32, 85, 83, 45, 65, 83, 67, 73, 73],
  )
  codec_assert_decode_encode(
    34,
    [2, 0, 1, 255],
    @telnet.OptionPayload::Linemode(
      @telnet.LinemodeMessage::ForwardMask(
        @telnet.LinemodeForwardMask::Bytes(span([0, 1, 255])),
      ),
    ),
    [2, 0, 1, 255],
  )
}
