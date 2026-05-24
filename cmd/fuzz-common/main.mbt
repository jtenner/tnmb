///| Shared pure helpers for the runnable TELNET fuzz harnesses.

///|

///| This package is intentionally used only by `cmd/fuzz` and

///| `cmd/fuzz-native`; the fast root-package fuzz tests keep local helpers so

///| the public TELNET package does not depend on command-only fuzz internals.

///|
pub(all) struct FuzzRng {
  state : Int
} derive(Eq, Debug)

///|
pub fn rng(seed : Int) -> FuzzRng {
  let normalized = seed % 65521
  let positive = if normalized < 0 { normalized + 65521 } else { normalized }
  FuzzRng::{ state: if positive == 0 { 1 } else { positive } }
}

///|
pub fn FuzzRng::next_int(self : FuzzRng) -> (FuzzRng, Int) {
  let next = (self.state * 25173 + 13849) % 65521
  (FuzzRng::{ state: next }, next)
}

///|
pub fn FuzzRng::bounded_int(self : FuzzRng, bound : Int) -> (FuzzRng, Int) {
  let (next, value) = self.next_int()
  if bound <= 0 {
    (next, 0)
  } else {
    (next, value % bound)
  }
}

///|
pub fn byte_from_int(n : Int) -> Byte {
  n.to_byte()
}

///|
pub fn FuzzRng::byte(self : FuzzRng) -> (FuzzRng, Byte) {
  let (next, value) = self.bounded_int(256)
  (next, byte_from_int(value))
}

///|
pub fn FuzzRng::chunk_boundary(
  self : FuzzRng,
  remaining : Int,
) -> (FuzzRng, Int) {
  if remaining <= 0 {
    let (next, _) = self.next_int()
    (next, 0)
  } else {
    self.bounded_int(remaining + 1)
  }
}

///|
pub fn telnet_biased_byte(choice : Int, fallback : Byte) -> Byte {
  match choice {
    0 | 1 | 2 => byte_from_int(255) // IAC, deliberately dense.
    3 => byte_from_int(240) // SE
    4 => byte_from_int(241) // NOP
    5 => byte_from_int(242) // DM
    6 => byte_from_int(250) // SB
    7 => byte_from_int(251) // WILL
    8 => byte_from_int(252) // WONT
    9 => byte_from_int(253) // DO
    10 => byte_from_int(254) // DONT
    11 => byte_from_int(13) // CR
    12 => byte_from_int(10) // LF
    13 => byte_from_int(0) // NUL / BINARY option
    14 => byte_from_int(1) // ECHO option
    15 => byte_from_int(3) // SUPPRESS-GO-AHEAD option
    16 => byte_from_int(24) // TERMINAL-TYPE option
    17 => byte_from_int(31) // NAWS option
    18 => byte_from_int(34) // LINEMODE option
    19 => byte_from_int(39) // NEW-ENVIRON option
    20 => byte_from_int(46) // START-TLS option
    _ => fallback
  }
}

///|
pub fn telnet_biased_bytes(seed : Int, length : Int) -> Bytes {
  let out = Array::make(length, byte_from_int(0))
  let mut rng = rng(seed)
  for i = 0; i < length; i = i + 1 {
    let (r1, choice) = rng.bounded_int(28)
    let (r2, fallback) = r1.byte()
    out[i] = telnet_biased_byte(choice, fallback)
    rng = r2
  }
  Bytes::from_array(out)
}

///|
pub fn parser_config(index : Int) -> @telnet.ParserConfig {
  if index == 0 {
    @telnet.Parser::default_config()
  } else if index == 1 {
    @telnet.ParserConfig::{
      max_data_chunk_bytes: 1,
      max_subnegotiation_bytes: 8,
      cr_policy: @telnet.CrPolicy::Preserve,
      data_coalescing: @telnet.DataCoalescing::EmitImmediately,
      strict_commands: true,
    }
  } else if index == 2 {
    @telnet.ParserConfig::{
      max_data_chunk_bytes: 4,
      max_subnegotiation_bytes: 4,
      cr_policy: @telnet.CrPolicy::ValidateNvt,
      data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
      strict_commands: true,
    }
  } else if index == 3 {
    @telnet.ParserConfig::{
      max_data_chunk_bytes: 3,
      max_subnegotiation_bytes: 3,
      cr_policy: @telnet.CrPolicy::NormalizeToLf,
      data_coalescing: @telnet.DataCoalescing::CoalesceUntilCapacity,
      strict_commands: false,
    }
  } else {
    @telnet.ParserConfig::{
      max_data_chunk_bytes: 0,
      max_subnegotiation_bytes: 0,
      cr_policy: @telnet.CrPolicy::Preserve,
      data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
      strict_commands: true,
    }
  }
}

///|
pub fn roundtrip_parser_config() -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 128,
    max_subnegotiation_bytes: 128,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
pub fn bytes_literal(data : Bytes) -> String {
  let mut out = "["
  for i = 0; i < data.length(); i = i + 1 {
    if i > 0 {
      out = out + ", "
    }
    out = out + data[i].to_int().to_string()
  }
  out + "]"
}

///|
pub fn concat_bytes(left : Bytes, right : Bytes) -> Bytes {
  Bytes::from_array(left.to_array() + right.to_array())
}

///|
pub fn bytes_slice(input : Bytes, start : Int, length : Int) -> Bytes {
  let out = Array::make(length, byte_from_int(0))
  for i = 0; i < length; i = i + 1 {
    out[i] = input[start + i]
  }
  Bytes::from_array(out)
}

///|
pub fn span_from_bytes(data : Bytes) -> @telnet.ByteSpan {
  @telnet.ByteSpan::{ bytes: data, start: 0, length: data.length() }
}

///|
pub fn one_byte_chunks(length : Int) -> Array[Int] {
  let chunks : Array[Int] = []
  chunks.push(0)
  for i = 0; i < length; i = i + 1 {
    chunks.push(1)
  }
  chunks.push(0)
  chunks
}
