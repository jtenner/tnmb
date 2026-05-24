// Deterministic fuzzing helpers for TELNET property tests.
//
// These helpers intentionally live in test code so future fuzz properties can
// share reproducible seeds without changing the public TELNET API.

///|
struct FuzzRng {
  state : Int
} derive(Eq, Debug)

///|
fn fuzz_rng(seed : Int) -> FuzzRng {
  let normalized = seed % 65521
  let positive = if normalized < 0 { normalized + 65521 } else { normalized }
  FuzzRng::{ state: if positive == 0 { 1 } else { positive } }
}

///|
fn FuzzRng::next_int(self : FuzzRng) -> (FuzzRng, Int) {
  let next = (self.state * 25173 + 13849) % 65521
  (FuzzRng::{ state: next }, next)
}

///|
fn FuzzRng::bounded_int(self : FuzzRng, bound : Int) -> (FuzzRng, Int) {
  let (next, value) = self.next_int()
  if bound <= 0 {
    (next, 0)
  } else {
    (next, value % bound)
  }
}

///|
fn FuzzRng::byte(self : FuzzRng) -> (FuzzRng, Byte) {
  let (next, value) = self.bounded_int(256)
  (next, byte(value))
}

///|
fn FuzzRng::bool(self : FuzzRng) -> (FuzzRng, Bool) {
  let (next, value) = self.bounded_int(2)
  (next, value == 1)
}

///|
fn FuzzRng::chunk_boundary(self : FuzzRng, remaining : Int) -> (FuzzRng, Int) {
  if remaining <= 0 {
    let (next, _) = self.next_int()
    (next, 0)
  } else {
    self.bounded_int(remaining + 1)
  }
}

///|
fn fuzz_bytes(seed : Int, length : Int) -> Bytes {
  let out = Array::make(length, byte(0))
  let mut rng = fuzz_rng(seed)
  for i = 0; i < length; i = i + 1 {
    let (next, x) = rng.byte()
    out[i] = x
    rng = next
  }
  Bytes::from_array(out)
}

///|
fn fuzz_bytes_from_ints(ns : Array[Int]) -> Bytes {
  Bytes::from_array(ns.map(fn(n) { byte(n) }))
}

///|
fn fuzz_no_iac_bytes(seed : Int, length : Int) -> Bytes {
  let out = Array::make(length, byte(0))
  let mut rng = fuzz_rng(seed)
  for i = 0; i < length; i = i + 1 {
    let (next, x) = rng.byte()
    out[i] = if x == byte(255) { byte(254) } else { x }
    rng = next
  }
  Bytes::from_array(out)
}

///|
fn fuzz_telnet_biased_byte(choice : Int, fallback : Byte) -> Byte {
  match choice {
    0 | 1 | 2 => byte(255) // IAC, deliberately dense.
    3 => byte(240) // SE
    4 => byte(241) // NOP
    5 => byte(242) // DM
    6 => byte(250) // SB
    7 => byte(251) // WILL
    8 => byte(252) // WONT
    9 => byte(253) // DO
    10 => byte(254) // DONT
    11 => byte(13) // CR
    12 => byte(10) // LF
    13 => byte(0) // NUL / BINARY option
    14 => byte(1) // ECHO option
    15 => byte(3) // SUPPRESS-GO-AHEAD option
    16 => byte(24) // TERMINAL-TYPE option
    17 => byte(31) // NAWS option
    18 => byte(34) // LINEMODE option
    19 => byte(39) // NEW-ENVIRON option
    20 => byte(46) // START-TLS option
    _ => fallback
  }
}

///|
fn fuzz_telnet_biased_bytes(seed : Int, length : Int) -> Bytes {
  let out = Array::make(length, byte(0))
  let mut rng = fuzz_rng(seed)
  for i = 0; i < length; i = i + 1 {
    let (r1, choice) = rng.bounded_int(28)
    let (r2, fallback) = r1.byte()
    out[i] = fuzz_telnet_biased_byte(choice, fallback)
    rng = r2
  }
  Bytes::from_array(out)
}

///|
fn fuzz_parser_config(index : Int) -> @telnet.ParserConfig {
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
fn fuzz_assert_parser_smoke(
  config : @telnet.ParserConfig,
  input : Bytes,
) -> Unit raise {
  let fed = @telnet.Parser::new(config).feed(input)
  assert_true(fed.bytes_consumed == input.length())
  let fed_checkpoint = fed.parser.checkpoint()
  assert_true(fed_checkpoint.absolute_offset == input.length())
  assert_true(fed_checkpoint.buffered_data_length >= 0)
  assert_true(fed_checkpoint.buffered_subnegotiation_length >= 0)
  assert_true(fed.events.length() <= input.length() + 1)

  let finished = fed.parser.finish()
  assert_true(finished.events.length() <= 1)
  let reset_checkpoint = finished.parser.checkpoint()
  assert_true(reset_checkpoint.mode == @telnet.ParserMode::Normal)
  assert_true(reset_checkpoint.absolute_offset == 0)
  assert_true(reset_checkpoint.buffered_data_length == 0)
  assert_true(reset_checkpoint.buffered_subnegotiation_length == 0)
}

///|
test "fuzz rng is deterministic for representative seeds" {
  let seed_one = fuzz_rng(1)
  let (r1, v1) = seed_one.next_int()
  let (r2, v2) = r1.next_int()
  let (r3, v3) = r2.next_int()
  assert_true(v1 == 39022)
  assert_true(v2 == 23823)
  assert_true(v3 == 62036)
  assert_true(r3 == FuzzRng::{ state: 62036 })

  let zero_seed = fuzz_rng(0)
  let (zero_next, zero_value) = zero_seed.next_int()
  assert_true(zero_seed == seed_one)
  assert_true(zero_value == 39022)
  assert_true(zero_next == r1)

  let negative_seed = fuzz_rng(-1)
  let (_, negative_value) = negative_seed.next_int()
  assert_true(negative_seed == FuzzRng::{ state: 65520 })
  assert_true(negative_value == 54197)
}

///|
test "fuzz rng supports bounded ints booleans bytes and chunk boundaries" {
  let rng = fuzz_rng(1)
  let (r1, bounded) = rng.bounded_int(10)
  let (r2, b1) = r1.bool()
  let (r3, x) = r2.byte()
  let (r4, boundary) = r3.chunk_boundary(5)
  let (r5, empty_boundary) = r4.chunk_boundary(0)
  let (r6, negative_boundary) = r5.chunk_boundary(-7)

  assert_true(bounded == 2)
  assert_true(b1)
  assert_true(x == byte(84))
  assert_true(boundary == 5)
  assert_true(empty_boundary == 0)
  assert_true(negative_boundary == 0)
  assert_true(r6 == FuzzRng::{ state: 57598 })

  let (after_zero_bound, zero_bound) = fuzz_rng(42).bounded_int(0)
  assert_true(zero_bound == 0)
  assert_true(after_zero_bound == FuzzRng::{ state: 22779 })
}

///|
test "fuzz byte helper produces reproducible byte buffers" {
  let generated = fuzz_bytes(1, 8)
  let expected = bytes([110, 15, 84, 131, 124, 254, 14, 8])
  assert_true(generated == expected)
  assert_true(fuzz_bytes(99, 0).length() == 0)
}

///|
test "parser smoke fuzz covers empty and every single byte" {
  for config_index = 0; config_index < 5; config_index = config_index + 1 {
    let config = fuzz_parser_config(config_index)
    fuzz_assert_parser_smoke(config, Bytes::new(0))
    for value = 0; value < 256; value = value + 1 {
      fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([value]))
    }
  }
}

///|
test "parser smoke fuzz covers targeted TELNET edge seeds" {
  for config_index = 0; config_index < 5; config_index = config_index + 1 {
    let config = fuzz_parser_config(config_index)
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 255]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 255, 255]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 241]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 251]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 251, 1]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 250]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 250, 31]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([255, 250, 31, 255]))
    fuzz_assert_parser_smoke(
      config,
      fuzz_bytes_from_ints([255, 250, 31, 255, 240]),
    )
    fuzz_assert_parser_smoke(
      config,
      fuzz_bytes_from_ints([255, 250, 31, 255, 255, 255, 240]),
    )
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([13]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([13, 10]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([13, 0]))
    fuzz_assert_parser_smoke(config, fuzz_bytes_from_ints([13, 88]))
  }
}

///|
test "parser smoke fuzz covers no-IAC fast paths and dense control streams" {
  for config_index = 0; config_index < 5; config_index = config_index + 1 {
    let config = fuzz_parser_config(config_index)
    for iteration = 0; iteration < 24; iteration = iteration + 1 {
      let no_iac_length = iteration * 7 % 65
      fuzz_assert_parser_smoke(
        config,
        fuzz_no_iac_bytes(1000 + config_index * 97 + iteration, no_iac_length),
      )
      let dense_length = (iteration * 11 + 3) % 73
      fuzz_assert_parser_smoke(
        config,
        fuzz_telnet_biased_bytes(
          2000 + config_index * 131 + iteration,
          dense_length,
        ),
      )
    }
  }
}

///|
enum FuzzObservedEvent {
  Data(Bytes)
  Command(@telnet.Command)
  Negotiation(@telnet.NegotiationEvent)
  Subnegotiation(@telnet.OptionCode, Bytes)
  Error(@telnet.TelnetError)
} derive(Eq, Debug)

///|
struct FuzzParseObservation {
  events : Array[FuzzObservedEvent]
  complete : Bool
} derive(Eq, Debug)

///|
fn fuzz_bytes_literal(data : Bytes) -> String {
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
fn fuzz_command_name(command : @telnet.Command) -> String {
  match command {
    @telnet.Command::SE => "SE"
    @telnet.Command::NOP => "NOP"
    @telnet.Command::DM => "DM"
    @telnet.Command::BRK => "BRK"
    @telnet.Command::IP => "IP"
    @telnet.Command::AO => "AO"
    @telnet.Command::AYT => "AYT"
    @telnet.Command::EC => "EC"
    @telnet.Command::EL => "EL"
    @telnet.Command::GA => "GA"
    @telnet.Command::SB => "SB"
    @telnet.Command::WILL => "WILL"
    @telnet.Command::WONT => "WONT"
    @telnet.Command::DO => "DO"
    @telnet.Command::DONT => "DONT"
    @telnet.Command::IAC => "IAC"
  }
}

///|
fn fuzz_negotiation_verb_name(verb : @telnet.NegotiationVerb) -> String {
  match verb {
    @telnet.NegotiationVerb::Will => "WILL"
    @telnet.NegotiationVerb::Wont => "WONT"
    @telnet.NegotiationVerb::Do => "DO"
    @telnet.NegotiationVerb::Dont => "DONT"
  }
}

///|
fn fuzz_error_kind_name(kind : @telnet.TelnetErrorKind) -> String {
  match kind {
    @telnet.TelnetErrorKind::IncompleteIac => "IncompleteIac"
    @telnet.TelnetErrorKind::IncompleteNegotiation => "IncompleteNegotiation"
    @telnet.TelnetErrorKind::IncompleteSubnegotiation =>
      "IncompleteSubnegotiation"
    @telnet.TelnetErrorKind::InvalidCommandByte => "InvalidCommandByte"
    @telnet.TelnetErrorKind::InvalidOptionByte => "InvalidOptionByte"
    @telnet.TelnetErrorKind::SubnegotiationTooLarge => "SubnegotiationTooLarge"
    @telnet.TelnetErrorKind::UnexpectedSubnegotiationEnd =>
      "UnexpectedSubnegotiationEnd"
    @telnet.TelnetErrorKind::PolicyRejected => "PolicyRejected"
    @telnet.TelnetErrorKind::UnsupportedOption => "UnsupportedOption"
  }
}

///|
fn fuzz_byte_option_summary(byte : Byte?) -> String {
  match byte {
    Some(value) => value.to_int().to_string()
    None => "none"
  }
}

///|
fn fuzz_option_summary(option : @telnet.OptionCode?) -> String {
  match option {
    Some(value) => value.value.to_int().to_string()
    None => "none"
  }
}

///|
fn fuzz_observed_event_summary(event : FuzzObservedEvent) -> String {
  match event {
    FuzzObservedEvent::Data(data) => "Data(" + fuzz_bytes_literal(data) + ")"
    FuzzObservedEvent::Command(command) =>
      "Command(" + fuzz_command_name(command) + ")"
    FuzzObservedEvent::Negotiation(event) =>
      "Negotiation(" +
      fuzz_negotiation_verb_name(event.verb) +
      ", " +
      event.option.value.to_int().to_string() +
      ")"
    FuzzObservedEvent::Subnegotiation(option, payload) =>
      "Subnegotiation(" +
      option.value.to_int().to_string() +
      ", " +
      fuzz_bytes_literal(payload) +
      ")"
    FuzzObservedEvent::Error(error) =>
      "Error(" +
      fuzz_error_kind_name(error.kind) +
      ", offset=" +
      error.offset.to_string() +
      ", byte=" +
      fuzz_byte_option_summary(error.byte) +
      ", option=" +
      fuzz_option_summary(error.option) +
      ")"
  }
}

///|
fn fuzz_observed_events_summary(events : Array[FuzzObservedEvent]) -> String {
  let mut out = "["
  for i = 0; i < events.length(); i = i + 1 {
    if i > 0 {
      out = out + ", "
    }
    out = out + fuzz_observed_event_summary(events[i])
  }
  out + "]"
}

///|
fn fuzz_observation_summary(observation : FuzzParseObservation) -> String {
  "complete=" +
  observation.complete.to_string() +
  " events=" +
  fuzz_observed_events_summary(observation.events)
}

///|
fn fuzz_parser_config_summary(config : @telnet.ParserConfig) -> String {
  "ParserConfig(max_data_chunk_bytes=" +
  config.max_data_chunk_bytes.to_string() +
  ", max_subnegotiation_bytes=" +
  config.max_subnegotiation_bytes.to_string() +
  ", cr_policy=" +
  fuzz_cr_policy_name(config.cr_policy) +
  ", data_coalescing=" +
  fuzz_data_coalescing_name(config.data_coalescing) +
  ", strict_commands=" +
  config.strict_commands.to_string() +
  ")"
}

///|
fn fuzz_reproduction_line(seed : Int, input : Bytes) -> String {
  "reproduce seed=" +
  seed.to_string() +
  " wire=bytes(" +
  fuzz_bytes_literal(input) +
  ")"
}

///|
test "fuzz failure byte literal helper formats regression-ready input" {
  assert_true(fuzz_bytes_literal(Bytes::new(0)) == "[]")
  assert_true(
    fuzz_bytes_literal(fuzz_bytes_from_ints([0, 13, 255])) == "[0, 13, 255]",
  )
}

///|
fn fuzz_concat_bytes(left : Bytes, right : Bytes) -> Bytes {
  Bytes::from_array(left.to_array() + right.to_array())
}

///|
fn fuzz_push_data_event(out : Array[FuzzObservedEvent], data : Bytes) -> Unit {
  if data.length() == 0 {
    return
  }
  if out.length() == 0 {
    out.push(FuzzObservedEvent::Data(data))
    return
  }
  let last_index = out.length() - 1
  match out[last_index] {
    FuzzObservedEvent::Data(existing) =>
      out[last_index] = FuzzObservedEvent::Data(
        fuzz_concat_bytes(existing, data),
      )
    _ => out.push(FuzzObservedEvent::Data(data))
  }
}

///|
fn fuzz_push_normalized_event(
  out : Array[FuzzObservedEvent],
  event : @telnet.Event,
) -> Unit {
  match event {
    @telnet.Event::Data(e) => fuzz_push_data_event(out, e.span.to_bytes())
    @telnet.Event::Command(e) => out.push(FuzzObservedEvent::Command(e.command))
    @telnet.Event::Negotiation(e) => out.push(FuzzObservedEvent::Negotiation(e))
    @telnet.Event::Subnegotiation(e) =>
      out.push(
        FuzzObservedEvent::Subnegotiation(e.option, e.payload.to_bytes()),
      )
    @telnet.Event::Error(e) => out.push(FuzzObservedEvent::Error(e))
  }
}

///|
fn fuzz_normalize_events(
  events : Array[@telnet.Event],
) -> Array[FuzzObservedEvent] {
  let out : Array[FuzzObservedEvent] = []
  events.each(fn(event) { fuzz_push_normalized_event(out, event) })
  out
}

///|
fn fuzz_bytes_slice(input : Bytes, start : Int, length : Int) -> Bytes {
  let out = Array::make(length, byte(0))
  for i = 0; i < length; i = i + 1 {
    out[i] = input[start + i]
  }
  Bytes::from_array(out)
}

///|
fn fuzz_observe_whole(
  config : @telnet.ParserConfig,
  input : Bytes,
) -> FuzzParseObservation {
  let fed = @telnet.Parser::new(config).feed(input)
  let finished = fed.parser.finish()
  FuzzParseObservation::{
    events: fuzz_normalize_events(fed.events + finished.events),
    complete: finished.complete,
  }
}

///|
fn fuzz_observe_chunks(
  config : @telnet.ParserConfig,
  input : Bytes,
  chunks : Array[Int],
) -> FuzzParseObservation raise {
  let mut parser = @telnet.Parser::new(config)
  let mut offset = 0
  let mut events : Array[@telnet.Event] = []
  chunks.each(fn(size) raise {
    assert_true(size >= 0)
    assert_true(offset + size <= input.length())
    let before = parser.checkpoint()
    let fed = parser.feed(fuzz_bytes_slice(input, offset, size))
    assert_true(fed.bytes_consumed == size)
    if size == 0 {
      assert_true(fed.events.length() == 0)
      assert_true(fed.parser.checkpoint() == before)
    }
    events = events + fed.events
    parser = fed.parser
    offset = offset + size
  })
  assert_true(offset == input.length())
  let finished = parser.finish()
  FuzzParseObservation::{
    events: fuzz_normalize_events(events + finished.events),
    complete: finished.complete,
  }
}

///|
fn fuzz_one_byte_chunks(length : Int) -> Array[Int] {
  let chunks : Array[Int] = []
  chunks.push(0)
  for i = 0; i < length; i = i + 1 {
    chunks.push(1)
    chunks.push(0)
  }
  chunks.push(0)
  chunks
}

///|
fn fuzz_random_chunks(seed : Int, length : Int) -> Array[Int] {
  let chunks : Array[Int] = []
  let mut rng = fuzz_rng(seed)
  let mut remaining = length
  chunks.push(0)
  while remaining > 0 {
    let (next, n) = rng.chunk_boundary(remaining)
    chunks.push(n)
    rng = next
    remaining = remaining - n
  }
  chunks.push(0)
  chunks
}

///|
struct FuzzKnownOptionCase {
  byte : Int
  known : @telnet.KnownOption
} derive(Eq, Debug)

///|
fn fuzz_known_option_name(option : @telnet.KnownOption) -> String {
  match option {
    @telnet.KnownOption::Binary => "Binary"
    @telnet.KnownOption::Echo => "Echo"
    @telnet.KnownOption::Reconnection => "Reconnection"
    @telnet.KnownOption::SuppressGoAhead => "SuppressGoAhead"
    @telnet.KnownOption::ApproxMessageSizeNegotiation =>
      "ApproxMessageSizeNegotiation"
    @telnet.KnownOption::Status => "Status"
    @telnet.KnownOption::TimingMark => "TimingMark"
    @telnet.KnownOption::RemoteControlledTransAndEcho =>
      "RemoteControlledTransAndEcho"
    @telnet.KnownOption::OutputLineWidth => "OutputLineWidth"
    @telnet.KnownOption::OutputPageSize => "OutputPageSize"
    @telnet.KnownOption::OutputCarriageReturnDisposition =>
      "OutputCarriageReturnDisposition"
    @telnet.KnownOption::OutputHorizontalTabStops => "OutputHorizontalTabStops"
    @telnet.KnownOption::OutputHorizontalTabDisposition =>
      "OutputHorizontalTabDisposition"
    @telnet.KnownOption::OutputFormfeedDisposition =>
      "OutputFormfeedDisposition"
    @telnet.KnownOption::OutputVerticalTabStops => "OutputVerticalTabStops"
    @telnet.KnownOption::OutputVerticalTabDisposition =>
      "OutputVerticalTabDisposition"
    @telnet.KnownOption::OutputLinefeedDisposition =>
      "OutputLinefeedDisposition"
    @telnet.KnownOption::ExtendedAscii => "ExtendedAscii"
    @telnet.KnownOption::Logout => "Logout"
    @telnet.KnownOption::ByteMacro => "ByteMacro"
    @telnet.KnownOption::DataEntryTerminal => "DataEntryTerminal"
    @telnet.KnownOption::Supdup => "Supdup"
    @telnet.KnownOption::SupdupOutput => "SupdupOutput"
    @telnet.KnownOption::SendLocation => "SendLocation"
    @telnet.KnownOption::TerminalType => "TerminalType"
    @telnet.KnownOption::EndOfRecord => "EndOfRecord"
    @telnet.KnownOption::TacacsUserIdentification => "TacacsUserIdentification"
    @telnet.KnownOption::OutputMarking => "OutputMarking"
    @telnet.KnownOption::TerminalLocationNumber => "TerminalLocationNumber"
    @telnet.KnownOption::Telnet3270Regime => "Telnet3270Regime"
    @telnet.KnownOption::X3Pad => "X3Pad"
    @telnet.KnownOption::Naws => "Naws"
    @telnet.KnownOption::TerminalSpeed => "TerminalSpeed"
    @telnet.KnownOption::RemoteFlowControl => "RemoteFlowControl"
    @telnet.KnownOption::Linemode => "Linemode"
    @telnet.KnownOption::XDisplayLocation => "XDisplayLocation"
    @telnet.KnownOption::Environment => "Environment"
    @telnet.KnownOption::Authentication => "Authentication"
    @telnet.KnownOption::Encryption => "Encryption"
    @telnet.KnownOption::NewEnvironment => "NewEnvironment"
    @telnet.KnownOption::Tn3270e => "Tn3270e"
    @telnet.KnownOption::Xauth => "Xauth"
    @telnet.KnownOption::Charset => "Charset"
    @telnet.KnownOption::TelnetRemoteSerialPort => "TelnetRemoteSerialPort"
    @telnet.KnownOption::ComPortControl => "ComPortControl"
    @telnet.KnownOption::TelnetSuppressLocalEcho => "TelnetSuppressLocalEcho"
    @telnet.KnownOption::TelnetStartTls => "TelnetStartTls"
    @telnet.KnownOption::Kermit => "Kermit"
    @telnet.KnownOption::SendUrl => "SendUrl"
    @telnet.KnownOption::ForwardX => "ForwardX"
    @telnet.KnownOption::ExtendedOptionsList => "ExtendedOptionsList"
    @telnet.KnownOption::Unknown(code) =>
      "Unknown(" + fuzz_option_code_summary(code) + ")"
  }
}

///|
fn fuzz_known_option_cases() -> Array[FuzzKnownOptionCase] {
  [
    FuzzKnownOptionCase::{ byte: 0, known: @telnet.KnownOption::Binary },
    FuzzKnownOptionCase::{ byte: 1, known: @telnet.KnownOption::Echo },
    FuzzKnownOptionCase::{ byte: 2, known: @telnet.KnownOption::Reconnection },
    FuzzKnownOptionCase::{
      byte: 3,
      known: @telnet.KnownOption::SuppressGoAhead,
    },
    FuzzKnownOptionCase::{
      byte: 4,
      known: @telnet.KnownOption::ApproxMessageSizeNegotiation,
    },
    FuzzKnownOptionCase::{ byte: 5, known: @telnet.KnownOption::Status },
    FuzzKnownOptionCase::{ byte: 6, known: @telnet.KnownOption::TimingMark },
    FuzzKnownOptionCase::{
      byte: 7,
      known: @telnet.KnownOption::RemoteControlledTransAndEcho,
    },
    FuzzKnownOptionCase::{
      byte: 8,
      known: @telnet.KnownOption::OutputLineWidth,
    },
    FuzzKnownOptionCase::{ byte: 9, known: @telnet.KnownOption::OutputPageSize },
    FuzzKnownOptionCase::{
      byte: 10,
      known: @telnet.KnownOption::OutputCarriageReturnDisposition,
    },
    FuzzKnownOptionCase::{
      byte: 11,
      known: @telnet.KnownOption::OutputHorizontalTabStops,
    },
    FuzzKnownOptionCase::{
      byte: 12,
      known: @telnet.KnownOption::OutputHorizontalTabDisposition,
    },
    FuzzKnownOptionCase::{
      byte: 13,
      known: @telnet.KnownOption::OutputFormfeedDisposition,
    },
    FuzzKnownOptionCase::{
      byte: 14,
      known: @telnet.KnownOption::OutputVerticalTabStops,
    },
    FuzzKnownOptionCase::{
      byte: 15,
      known: @telnet.KnownOption::OutputVerticalTabDisposition,
    },
    FuzzKnownOptionCase::{
      byte: 16,
      known: @telnet.KnownOption::OutputLinefeedDisposition,
    },
    FuzzKnownOptionCase::{ byte: 17, known: @telnet.KnownOption::ExtendedAscii },
    FuzzKnownOptionCase::{ byte: 18, known: @telnet.KnownOption::Logout },
    FuzzKnownOptionCase::{ byte: 19, known: @telnet.KnownOption::ByteMacro },
    FuzzKnownOptionCase::{
      byte: 20,
      known: @telnet.KnownOption::DataEntryTerminal,
    },
    FuzzKnownOptionCase::{ byte: 21, known: @telnet.KnownOption::Supdup },
    FuzzKnownOptionCase::{ byte: 22, known: @telnet.KnownOption::SupdupOutput },
    FuzzKnownOptionCase::{ byte: 23, known: @telnet.KnownOption::SendLocation },
    FuzzKnownOptionCase::{ byte: 24, known: @telnet.KnownOption::TerminalType },
    FuzzKnownOptionCase::{ byte: 25, known: @telnet.KnownOption::EndOfRecord },
    FuzzKnownOptionCase::{
      byte: 26,
      known: @telnet.KnownOption::TacacsUserIdentification,
    },
    FuzzKnownOptionCase::{ byte: 27, known: @telnet.KnownOption::OutputMarking },
    FuzzKnownOptionCase::{
      byte: 28,
      known: @telnet.KnownOption::TerminalLocationNumber,
    },
    FuzzKnownOptionCase::{
      byte: 29,
      known: @telnet.KnownOption::Telnet3270Regime,
    },
    FuzzKnownOptionCase::{ byte: 30, known: @telnet.KnownOption::X3Pad },
    FuzzKnownOptionCase::{ byte: 31, known: @telnet.KnownOption::Naws },
    FuzzKnownOptionCase::{ byte: 32, known: @telnet.KnownOption::TerminalSpeed },
    FuzzKnownOptionCase::{
      byte: 33,
      known: @telnet.KnownOption::RemoteFlowControl,
    },
    FuzzKnownOptionCase::{ byte: 34, known: @telnet.KnownOption::Linemode },
    FuzzKnownOptionCase::{
      byte: 35,
      known: @telnet.KnownOption::XDisplayLocation,
    },
    FuzzKnownOptionCase::{ byte: 36, known: @telnet.KnownOption::Environment },
    FuzzKnownOptionCase::{
      byte: 37,
      known: @telnet.KnownOption::Authentication,
    },
    FuzzKnownOptionCase::{ byte: 38, known: @telnet.KnownOption::Encryption },
    FuzzKnownOptionCase::{
      byte: 39,
      known: @telnet.KnownOption::NewEnvironment,
    },
    FuzzKnownOptionCase::{ byte: 40, known: @telnet.KnownOption::Tn3270e },
    FuzzKnownOptionCase::{ byte: 41, known: @telnet.KnownOption::Xauth },
    FuzzKnownOptionCase::{ byte: 42, known: @telnet.KnownOption::Charset },
    FuzzKnownOptionCase::{
      byte: 43,
      known: @telnet.KnownOption::TelnetRemoteSerialPort,
    },
    FuzzKnownOptionCase::{
      byte: 44,
      known: @telnet.KnownOption::ComPortControl,
    },
    FuzzKnownOptionCase::{
      byte: 45,
      known: @telnet.KnownOption::TelnetSuppressLocalEcho,
    },
    FuzzKnownOptionCase::{
      byte: 46,
      known: @telnet.KnownOption::TelnetStartTls,
    },
    FuzzKnownOptionCase::{ byte: 47, known: @telnet.KnownOption::Kermit },
    FuzzKnownOptionCase::{ byte: 48, known: @telnet.KnownOption::SendUrl },
    FuzzKnownOptionCase::{ byte: 49, known: @telnet.KnownOption::ForwardX },
    FuzzKnownOptionCase::{
      byte: 255,
      known: @telnet.KnownOption::ExtendedOptionsList,
    },
  ]
}

///|
fn fuzz_print_option_catalog_failure(
  phase : String,
  value : Int,
  expected : @telnet.KnownOption,
  observed : @telnet.KnownOption,
) -> Unit {
  println(
    "option catalog fuzz phase=" +
    phase +
    " byte=" +
    value.to_string() +
    " expected=" +
    fuzz_known_option_name(expected) +
    " observed=" +
    fuzz_known_option_name(observed),
  )
}

///|
fn fuzz_assert_option_catalog_case(case : FuzzKnownOptionCase) -> Unit {
  let code = @telnet.OptionCode::new(byte(case.byte))
  let from_code = @telnet.KnownOption::from_code(code)
  if from_code != case.known {
    fuzz_print_option_catalog_failure(
      "from_code",
      case.byte,
      case.known,
      from_code,
    )
    abort("option catalog from_code mismatch")
  }
  let to_code = case.known.to_code()
  if to_code != code {
    println(
      "option catalog fuzz phase=to_code byte=" +
      case.byte.to_string() +
      " known=" +
      fuzz_known_option_name(case.known) +
      " observed_code=" +
      fuzz_option_code_summary(to_code),
    )
    abort("option catalog to_code mismatch")
  }
  let roundtrip = @telnet.KnownOption::from_code(to_code)
  if roundtrip != case.known {
    fuzz_print_option_catalog_failure(
      "named-roundtrip",
      case.byte,
      case.known,
      roundtrip,
    )
    abort("option catalog named roundtrip mismatch")
  }
}

///|
test "option catalog fuzz covers all named known option mappings" {
  let cases = fuzz_known_option_cases()
  let seen = Array::make(256, false)
  assert_true(cases.length() == 51)
  cases.each(fn(case) raise {
    assert_true(case.byte >= 0 && case.byte < 256)
    assert_true(!seen[case.byte])
    seen[case.byte] = true
    fuzz_assert_option_catalog_case(case)
  })
  for value = 0; value < 256; value = value + 1 {
    let code = @telnet.OptionCode::new(byte(value))
    let known = @telnet.KnownOption::from_code(code)
    if seen[value] {
      assert_true(known.to_code() == code)
    } else if known != @telnet.KnownOption::Unknown(code) {
      fuzz_print_option_catalog_failure(
        "unknown-preservation",
        value,
        @telnet.KnownOption::Unknown(code),
        known,
      )
      abort("option catalog unknown preservation mismatch")
    } else {
      assert_true(known.to_code() == code)
    }
  }
}

///|
fn fuzz_command_catalog_config(strict : Bool) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 64,
    max_subnegotiation_bytes: 64,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: strict,
  }
}

///|
fn fuzz_negotiation_verb_from_command_byte(
  value : Int,
) -> @telnet.NegotiationVerb {
  match value {
    251 => @telnet.NegotiationVerb::Will
    252 => @telnet.NegotiationVerb::Wont
    253 => @telnet.NegotiationVerb::Do
    _ => @telnet.NegotiationVerb::Dont
  }
}

///|
fn fuzz_expected_iac_slot_observation(value : Int) -> FuzzParseObservation {
  if value == 255 {
    FuzzParseObservation::{
      events: [FuzzObservedEvent::Data(fuzz_bytes_from_ints([255]))],
      complete: true,
    }
  } else if value == 240 {
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::UnexpectedSubnegotiationEnd,
          offset: 1,
          byte: Some(byte(value)),
          option: None,
        }),
      ],
      complete: true,
    }
  } else if value == 250 {
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::IncompleteSubnegotiation,
          offset: 1,
          byte: None,
          option: None,
        }),
      ],
      complete: false,
    }
  } else if value >= 251 && value <= 254 {
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::IncompleteNegotiation,
          offset: 1,
          byte: Some(byte(value)),
          option: None,
        }),
      ],
      complete: false,
    }
  } else {
    match @telnet.Command::from_byte(byte(value)) {
      Some(command) =>
        FuzzParseObservation::{
          events: [FuzzObservedEvent::Command(command)],
          complete: true,
        }
      None =>
        FuzzParseObservation::{
          events: [
            FuzzObservedEvent::Error(@telnet.TelnetError::{
              kind: @telnet.TelnetErrorKind::InvalidCommandByte,
              offset: 1,
              byte: Some(byte(value)),
              option: None,
            }),
          ],
          complete: true,
        }
    }
  }
}

///|
fn fuzz_print_command_catalog_failure(
  phase : String,
  value : Int,
  strict : Bool,
  wire : Bytes,
  expected : FuzzParseObservation,
  observed : FuzzParseObservation,
) -> Unit {
  println(
    "command catalog fuzz phase=" +
    phase +
    " byte=" +
    value.to_string() +
    " strict=" +
    strict.to_string() +
    " wire=" +
    fuzz_bytes_literal(wire),
  )
  println("expected " + fuzz_observation_summary(expected))
  println("observed " + fuzz_observation_summary(observed))
}

///|
fn fuzz_assert_iac_slot_case(value : Int, strict : Bool) -> Unit raise {
  let config = fuzz_command_catalog_config(strict)
  let wire = fuzz_bytes_from_ints([255, value])
  let expected = fuzz_expected_iac_slot_observation(value)
  let observed = fuzz_observe_whole(config, wire)
  if observed != expected {
    fuzz_print_command_catalog_failure(
      "whole-iac-slot", value, strict, wire, expected, observed,
    )
    abort("command catalog whole IAC slot mismatch")
  }
  let chunked = fuzz_observe_chunks(
    config,
    wire,
    fuzz_one_byte_chunks(wire.length()),
  )
  if chunked != observed {
    fuzz_print_command_catalog_failure(
      "chunked-iac-slot", value, strict, wire, observed, chunked,
    )
    abort("command catalog chunked IAC slot mismatch")
  }
}

///|
test "command catalog fuzz covers every mapping helper byte" {
  for value = 0; value < 256; value = value + 1 {
    match @telnet.Command::from_byte(byte(value)) {
      Some(command) => {
        if value < 240 || command.to_byte() != byte(value) {
          println(
            "command catalog fuzz phase=from_byte byte=" +
            value.to_string() +
            " command=" +
            fuzz_command_name(command) +
            " to_byte=" +
            command.to_byte().to_int().to_string(),
          )
          abort("command catalog from_byte/to_byte mismatch")
        }
        match @telnet.NegotiationVerb::from_command(command) {
          Some(verb) =>
            if value < 251 || value > 254 || verb.to_command() != command {
              println(
                "command catalog fuzz phase=negotiation-verb byte=" +
                value.to_string() +
                " command=" +
                fuzz_command_name(command) +
                " verb=" +
                fuzz_negotiation_verb_name(verb),
              )
              abort("command catalog negotiation verb mismatch")
            }
          None => assert_true(value < 251 || value > 254)
        }
      }
      None => assert_true(value < 240)
    }
  }
}

///|
test "command catalog fuzz covers parser IAC command slots" {
  for value = 0; value < 256; value = value + 1 {
    fuzz_assert_iac_slot_case(value, true)
    fuzz_assert_iac_slot_case(value, false)
  }
}

///|
test "command catalog fuzz covers negotiation option bytes" {
  let config = fuzz_command_catalog_config(true)
  for verb_byte = 251; verb_byte <= 254; verb_byte = verb_byte + 1 {
    let verb = fuzz_negotiation_verb_from_command_byte(verb_byte)
    for option = 0; option < 256; option = option + 1 {
      let wire = fuzz_bytes_from_ints([255, verb_byte, option])
      let expected = FuzzParseObservation::{
        events: [
          FuzzObservedEvent::Negotiation(@telnet.NegotiationEvent::{
            verb,
            option: @telnet.OptionCode::new(byte(option)),
          }),
        ],
        complete: true,
      }
      let observed = fuzz_observe_whole(config, wire)
      if observed != expected {
        fuzz_print_command_catalog_failure(
          "negotiation-option", option, true, wire, expected, observed,
        )
        println("verb_byte=" + verb_byte.to_string())
        abort("command catalog negotiation option mismatch")
      }
    }
  }
}

///|
test "command catalog fuzz covers subnegotiation option bytes" {
  let config = fuzz_command_catalog_config(true)
  for option = 0; option < 256; option = option + 1 {
    let wire = fuzz_bytes_from_ints([255, 250, option, 255, 240])
    let expected = FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Subnegotiation(
          @telnet.OptionCode::new(byte(option)),
          Bytes::new(0),
        ),
      ],
      complete: true,
    }
    let observed = fuzz_observe_whole(config, wire)
    if observed != expected {
      fuzz_print_command_catalog_failure(
        "subnegotiation-option", option, true, wire, expected, observed,
      )
      abort("command catalog subnegotiation option mismatch")
    }
  }
}

///|
fn fuzz_print_streaming_mismatch(
  phase : String,
  seed : Int,
  input : Bytes,
  config : @telnet.ParserConfig,
  chunks : Array[Int],
  whole : FuzzParseObservation,
  chunked : FuzzParseObservation,
) -> Unit {
  println(
    "streaming fuzz phase=" + phase + " " + fuzz_reproduction_line(seed, input),
  )
  println("length=" + input.length().to_string())
  println("config=" + fuzz_parser_config_summary(config))
  println("chunks=" + fuzz_int_array_literal(chunks))
  println("whole " + fuzz_observation_summary(whole))
  println("chunked " + fuzz_observation_summary(chunked))
}

///|
fn fuzz_assert_streaming_equivalent(
  config : @telnet.ParserConfig,
  input : Bytes,
  seed : Int,
) -> Unit raise {
  let whole = fuzz_observe_whole(config, input)
  let one_byte_chunks = fuzz_one_byte_chunks(input.length())
  let single = fuzz_observe_chunks(config, input, one_byte_chunks)
  if single != whole {
    fuzz_print_streaming_mismatch(
      "one-byte-with-empty-feeds", seed, input, config, one_byte_chunks, whole, single,
    )
    abort("streaming single-byte mismatch")
  }

  if input.length() <= 16 {
    for split = 0; split <= input.length(); split = split + 1 {
      let split_chunks = [0, split, 0, input.length() - split, 0]
      let split_observed = fuzz_observe_chunks(config, input, split_chunks)
      if split_observed != whole {
        fuzz_print_streaming_mismatch(
          "split-" + split.to_string(),
          seed,
          input,
          config,
          split_chunks,
          whole,
          split_observed,
        )
        abort("streaming split mismatch")
      }
    }
  }

  for pattern = 0; pattern < 3; pattern = pattern + 1 {
    let chunk_seed = seed + pattern * 655
    let random_chunks = fuzz_random_chunks(chunk_seed, input.length())
    let chunked = fuzz_observe_chunks(config, input, random_chunks)
    if chunked != whole {
      fuzz_print_streaming_mismatch(
        "random-pattern-" +
        pattern.to_string() +
        " chunk_seed=" +
        chunk_seed.to_string(),
        seed,
        input,
        config,
        random_chunks,
        whole,
        chunked,
      )
      abort("streaming random mismatch")
    }
  }
}

///|
test "parser streaming fuzz keeps empty feeds and pending CR equivalent" {
  let validate = fuzz_parser_config(2)
  fuzz_assert_streaming_equivalent(
    validate,
    fuzz_bytes_from_ints([13, 10]),
    3001,
  )
  fuzz_assert_streaming_equivalent(
    validate,
    fuzz_bytes_from_ints([254, 73, 240, 34, 255, 134, 252, 27, 13, 240, 97, 218]),
    7515,
  )
  fuzz_assert_streaming_equivalent(
    validate,
    fuzz_bytes_from_ints([31, 31, 3, 39, 13, 255, 251]),
    7526,
  )
  let normalize = fuzz_parser_config(3)
  fuzz_assert_streaming_equivalent(
    normalize,
    fuzz_bytes_from_ints([13, 88]),
    3002,
  )

  let parser = @telnet.Parser::new(normalize)
  let first = parser.feed(fuzz_bytes_from_ints([13]))
  let before_empty = first.parser.checkpoint()
  let empty = first.parser.feed(Bytes::new(0))
  assert_true(empty.bytes_consumed == 0)
  assert_true(empty.events.length() == 0)
  assert_true(empty.parser.checkpoint() == before_empty)
}

///|
test "parser streaming fuzz covers targeted TELNET edge seeds" {
  for config_index = 0; config_index < 5; config_index = config_index + 1 {
    let config = fuzz_parser_config(config_index)
    fuzz_assert_streaming_equivalent(
      config,
      fuzz_bytes_from_ints([]),
      3100 + config_index,
    )
    fuzz_assert_streaming_equivalent(
      config,
      fuzz_bytes_from_ints([255]),
      3110 + config_index,
    )
    fuzz_assert_streaming_equivalent(
      config,
      fuzz_bytes_from_ints([255, 255]),
      3120 + config_index,
    )
    fuzz_assert_streaming_equivalent(
      config,
      fuzz_bytes_from_ints([255, 251, 1]),
      3130 + config_index,
    )
    fuzz_assert_streaming_equivalent(
      config,
      fuzz_bytes_from_ints([255, 250, 31, 255, 255, 255, 240]),
      3140 + config_index,
    )
    fuzz_assert_streaming_equivalent(
      config,
      fuzz_bytes_from_ints([13]),
      3150 + config_index,
    )
    fuzz_assert_streaming_equivalent(
      config,
      fuzz_bytes_from_ints([13, 10]),
      3160 + config_index,
    )
    fuzz_assert_streaming_equivalent(
      config,
      fuzz_bytes_from_ints([13, 0]),
      3170 + config_index,
    )
    fuzz_assert_streaming_equivalent(
      config,
      fuzz_bytes_from_ints([13, 88]),
      3180 + config_index,
    )
  }
}

///|
test "parser streaming fuzz covers generated fast paths and dense streams" {
  for config_index = 0; config_index < 5; config_index = config_index + 1 {
    let config = fuzz_parser_config(config_index)
    for iteration = 0; iteration < 16; iteration = iteration + 1 {
      let no_iac_length = iteration * 5 % 33
      fuzz_assert_streaming_equivalent(
        config,
        fuzz_no_iac_bytes(4000 + config_index * 97 + iteration, no_iac_length),
        5000 + config_index * 257 + iteration,
      )
      let dense_length = (iteration * 7 + 5) % 41
      fuzz_assert_streaming_equivalent(
        config,
        fuzz_telnet_biased_bytes(
          6000 + config_index * 131 + iteration,
          dense_length,
        ),
        7000 + config_index * 257 + iteration,
      )
    }
  }
}

///|
fn fuzz_cr_policy_name(policy : @telnet.CrPolicy) -> String {
  match policy {
    @telnet.CrPolicy::Preserve => "Preserve"
    @telnet.CrPolicy::ValidateNvt => "ValidateNvt"
    @telnet.CrPolicy::NormalizeToLf => "NormalizeToLf"
  }
}

///|
fn fuzz_data_coalescing_name(coalescing : @telnet.DataCoalescing) -> String {
  match coalescing {
    @telnet.DataCoalescing::EmitImmediately => "EmitImmediately"
    @telnet.DataCoalescing::CoalesceUntilCommand => "CoalesceUntilCommand"
    @telnet.DataCoalescing::CoalesceUntilCapacity => "CoalesceUntilCapacity"
  }
}

///|
fn fuzz_newline_config(
  policy : @telnet.CrPolicy,
  coalescing : @telnet.DataCoalescing,
  max_data_chunk_bytes : Int,
) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes,
    max_subnegotiation_bytes: 64,
    cr_policy: policy,
    data_coalescing: coalescing,
    strict_commands: true,
  }
}

///|
fn fuzz_flush_reference_data(
  out : Array[FuzzObservedEvent],
  data : Array[Byte],
) -> Unit {
  if data.length() > 0 {
    fuzz_push_data_event(out, Bytes::from_array(data.copy()))
    data.clear()
  }
}

///|
fn fuzz_reference_no_iac_newline_observation(
  policy : @telnet.CrPolicy,
  input : Bytes,
) -> FuzzParseObservation {
  let events : Array[FuzzObservedEvent] = []
  let data : Array[Byte] = []
  let mut complete = true
  let mut i = 0
  while i < input.length() {
    let value = input[i]
    if policy == @telnet.CrPolicy::Preserve {
      data.push(value)
    } else if value == byte(13) {
      if i + 1 == input.length() {
        fuzz_flush_reference_data(events, data)
        events.push(
          FuzzObservedEvent::Error(@telnet.TelnetError::{
            kind: @telnet.TelnetErrorKind::PolicyRejected,
            offset: i,
            byte: Some(byte(13)),
            option: None,
          }),
        )
        complete = false
      } else {
        let next = input[i + 1]
        if policy == @telnet.CrPolicy::ValidateNvt {
          if next == byte(10) || next == byte(0) {
            data.push(byte(13))
            data.push(next)
            i = i + 1
          } else {
            fuzz_flush_reference_data(events, data)
            events.push(
              FuzzObservedEvent::Error(@telnet.TelnetError::{
                kind: @telnet.TelnetErrorKind::PolicyRejected,
                offset: i + 1,
                byte: Some(next),
                option: None,
              }),
            )
          }
        } else if next == byte(10) {
          data.push(byte(10))
          i = i + 1
        } else if next == byte(0) {
          data.push(byte(13))
          i = i + 1
        } else {
          data.push(byte(13))
        }
      }
    } else {
      data.push(value)
    }
    i = i + 1
  }
  fuzz_flush_reference_data(events, data)
  FuzzParseObservation::{ events, complete }
}

///|
fn fuzz_newline_failure_prefix(
  case_name : String,
  seed : Int,
  config : @telnet.ParserConfig,
  input : Bytes,
) -> String {
  "newline fuzz case=" +
  case_name +
  " seed=" +
  seed.to_string() +
  " length=" +
  input.length().to_string() +
  " cr_policy=" +
  fuzz_cr_policy_name(config.cr_policy) +
  " coalescing=" +
  fuzz_data_coalescing_name(config.data_coalescing) +
  " max_data_chunk_bytes=" +
  config.max_data_chunk_bytes.to_string() +
  " wire=" +
  fuzz_bytes_literal(input)
}

///|
fn fuzz_assert_newline_observation(
  case_name : String,
  config : @telnet.ParserConfig,
  input : Bytes,
  expected : FuzzParseObservation,
  seed : Int,
) -> Unit {
  let observed = fuzz_observe_whole(config, input)
  if observed != expected {
    println(fuzz_newline_failure_prefix(case_name, seed, config, input))
    println("expected " + fuzz_observation_summary(expected))
    println("observed " + fuzz_observation_summary(observed))
    abort("newline fuzz observation mismatch")
  }
}

///|
fn fuzz_assert_newline_streaming_matches(
  case_name : String,
  config : @telnet.ParserConfig,
  input : Bytes,
  chunks : Array[Int],
  whole : FuzzParseObservation,
  seed : Int,
) -> Unit raise {
  let chunked = fuzz_observe_chunks(config, input, chunks)
  if chunked != whole {
    println(fuzz_newline_failure_prefix(case_name, seed, config, input))
    println("chunks=" + fuzz_int_array_literal(chunks))
    println("whole " + fuzz_observation_summary(whole))
    println("chunked " + fuzz_observation_summary(chunked))
    abort("newline fuzz streaming mismatch")
  }
}

///|
fn fuzz_assert_newline_case(
  case_name : String,
  config : @telnet.ParserConfig,
  input : Bytes,
  expected : FuzzParseObservation,
  seed : Int,
) -> Unit raise {
  fuzz_assert_parser_smoke(config, input)
  fuzz_assert_newline_observation(case_name, config, input, expected, seed)
  let whole = fuzz_observe_whole(config, input)
  for split = 0; split <= input.length(); split = split + 1 {
    fuzz_assert_newline_streaming_matches(
      case_name,
      config,
      input,
      [0, split, 0, input.length() - split, 0],
      whole,
      seed,
    )
  }
  fuzz_assert_newline_streaming_matches(
    case_name,
    config,
    input,
    fuzz_one_byte_chunks(input.length()),
    whole,
    seed,
  )
}

///|
fn fuzz_assert_no_iac_newline_case(
  case_name : String,
  policy : @telnet.CrPolicy,
  input : Bytes,
  seed : Int,
) -> Unit raise {
  let config = fuzz_newline_config(
    policy,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    128,
  )
  fuzz_assert_newline_case(
    case_name,
    config,
    input,
    fuzz_reference_no_iac_newline_observation(policy, input),
    seed,
  )
}

///|
fn fuzz_crlf_biased_no_iac_byte(choice : Int, fallback : Byte) -> Byte {
  match choice {
    0 | 1 | 2 => byte(13)
    3 | 4 => byte(10)
    5 | 6 => byte(0)
    7 => byte(65)
    8 => byte(90)
    9 => byte(127)
    10 => byte(128)
    11 => byte(254)
    _ => if fallback == byte(255) { byte(42) } else { fallback }
  }
}

///|
fn fuzz_crlf_biased_no_iac_bytes(seed : Int, length : Int) -> Bytes {
  let out = Array::make(length, byte(0))
  let mut rng = fuzz_rng(seed)
  for i = 0; i < length; i = i + 1 {
    let (r1, choice) = rng.bounded_int(18)
    let (r2, fallback) = r1.byte()
    out[i] = fuzz_crlf_biased_no_iac_byte(choice, fallback)
    rng = r2
  }
  Bytes::from_array(out)
}

///|
test "newline fuzz covers NVT CR LF NUL policy cases" {
  let seeds = [
    fuzz_bytes_from_ints([]),
    fuzz_bytes_from_ints([13]),
    fuzz_bytes_from_ints([10]),
    fuzz_bytes_from_ints([0]),
    fuzz_bytes_from_ints([13, 10]),
    fuzz_bytes_from_ints([13, 0]),
    fuzz_bytes_from_ints([13, 88]),
    fuzz_bytes_from_ints([65, 13, 10, 66]),
    fuzz_bytes_from_ints([65, 13, 0, 66]),
    fuzz_bytes_from_ints([65, 13, 88, 13, 10, 0]),
    fuzz_bytes_from_ints([13, 13, 10, 13, 0, 10]),
    fuzz_bytes_from_ints([0, 13, 0, 10, 13, 90]),
  ]
  let policies = [
    @telnet.CrPolicy::Preserve,
    @telnet.CrPolicy::ValidateNvt,
    @telnet.CrPolicy::NormalizeToLf,
  ]
  for policy_index = 0
      policy_index < policies.length()
      policy_index = policy_index + 1 {
    for case_index = 0; case_index < seeds.length(); case_index = case_index + 1 {
      fuzz_assert_no_iac_newline_case(
        "targeted-" + case_index.to_string(),
        policies[policy_index],
        seeds[case_index],
        14000 + policy_index * 100 + case_index,
      )
    }
  }
}

///|
test "newline fuzz covers generated CR LF NUL biased text streams" {
  let policies = [
    @telnet.CrPolicy::Preserve,
    @telnet.CrPolicy::ValidateNvt,
    @telnet.CrPolicy::NormalizeToLf,
  ]
  for policy_index = 0
      policy_index < policies.length()
      policy_index = policy_index + 1 {
    for iteration = 0; iteration < 24; iteration = iteration + 1 {
      let length = (iteration * 7 + policy_index * 3) % 37
      fuzz_assert_no_iac_newline_case(
        "generated-" + iteration.to_string(),
        policies[policy_index],
        fuzz_crlf_biased_no_iac_bytes(
          14100 + policy_index * 257 + iteration,
          length,
        ),
        14100 + policy_index * 257 + iteration,
      )
    }
  }
}

///|
test "newline fuzz documents Preserve as current binary-like core mode" {
  // The core parser has no negotiated BINARY session state yet.  Fuzzer
  // coverage treats Preserve as the binary-like parser configuration: mixed
  // bytes, including CR/LF/NUL, are emitted unchanged unless TELNET IAC
  // framing is present. NVT CR validation/normalization is opt-in via
  // ParserConfig::cr_policy and is covered separately above.
  let config = fuzz_newline_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    128,
  )
  let input = fuzz_bytes_from_ints([0, 13, 10, 128, 254, 13, 0, 42])
  fuzz_assert_newline_case(
    "preserve-mixed-binary-bytes",
    config,
    input,
    FuzzParseObservation::{
      events: [FuzzObservedEvent::Data(input)],
      complete: true,
    },
    14200,
  )
}

///|
test "newline fuzz covers command boundaries around CR" {
  let preserve = fuzz_newline_config(
    @telnet.CrPolicy::Preserve,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    128,
  )
  let validate = fuzz_newline_config(
    @telnet.CrPolicy::ValidateNvt,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    128,
  )
  let normalize = fuzz_newline_config(
    @telnet.CrPolicy::NormalizeToLf,
    @telnet.DataCoalescing::CoalesceUntilCommand,
    128,
  )
  fuzz_assert_newline_case(
    "preserve-cr-before-command",
    preserve,
    fuzz_bytes_from_ints([13, 255, 241, 10]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Data(fuzz_bytes_from_ints([13])),
        FuzzObservedEvent::Command(@telnet.Command::NOP),
        FuzzObservedEvent::Data(fuzz_bytes_from_ints([10])),
      ],
      complete: true,
    },
    14300,
  )
  fuzz_assert_newline_case(
    "validate-cr-before-command-rejects-iac-as-cr-follower",
    validate,
    fuzz_bytes_from_ints([13, 255, 241, 10]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::PolicyRejected,
          offset: 1,
          byte: Some(byte(255)),
          option: None,
        }),
        FuzzObservedEvent::Command(@telnet.Command::NOP),
        FuzzObservedEvent::Data(fuzz_bytes_from_ints([10])),
      ],
      complete: true,
    },
    14301,
  )
  fuzz_assert_newline_case(
    "normalize-cr-before-command-keeps-bare-cr",
    normalize,
    fuzz_bytes_from_ints([13, 255, 241, 10]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Data(fuzz_bytes_from_ints([13])),
        FuzzObservedEvent::Command(@telnet.Command::NOP),
        FuzzObservedEvent::Data(fuzz_bytes_from_ints([10])),
      ],
      complete: true,
    },
    14302,
  )
  fuzz_assert_newline_case(
    "normalize-command-before-crlf",
    normalize,
    fuzz_bytes_from_ints([255, 241, 13, 10, 65]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Command(@telnet.Command::NOP),
        FuzzObservedEvent::Data(fuzz_bytes_from_ints([10, 65])),
      ],
      complete: true,
    },
    14303,
  )
}

///|
fn fuzz_roundtrip_parser_config() -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 128,
    max_subnegotiation_bytes: 128,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
fn fuzz_span_suffix(seed : Int, payload : Bytes) -> @telnet.ByteSpan {
  let prefix_len = seed % 4 + 1
  let out = Array::make(prefix_len + payload.length(), byte(0))
  let mut rng = fuzz_rng(seed + 17)
  for i = 0; i < prefix_len; i = i + 1 {
    let (next, x) = rng.byte()
    out[i] = x
    rng = next
  }
  for i = 0; i < payload.length(); i = i + 1 {
    out[prefix_len + i] = payload[i]
  }
  @telnet.ByteSpan::{
    bytes: Bytes::from_array(out),
    start: prefix_len,
    length: payload.length(),
  }
}

///|
fn fuzz_simple_command(index : Int) -> @telnet.Command {
  match index % 9 {
    0 => @telnet.Command::NOP
    1 => @telnet.Command::DM
    2 => @telnet.Command::BRK
    3 => @telnet.Command::IP
    4 => @telnet.Command::AO
    5 => @telnet.Command::AYT
    6 => @telnet.Command::EC
    7 => @telnet.Command::EL
    _ => @telnet.Command::GA
  }
}

///|
fn fuzz_negotiation_verb(index : Int) -> @telnet.NegotiationVerb {
  match index % 4 {
    0 => @telnet.NegotiationVerb::Will
    1 => @telnet.NegotiationVerb::Wont
    2 => @telnet.NegotiationVerb::Do
    _ => @telnet.NegotiationVerb::Dont
  }
}

///|
fn fuzz_roundtrip_payload(seed : Int, max_length : Int) -> Bytes {
  let (rng, length) = fuzz_rng(seed).bounded_int(max_length + 1)
  fuzz_telnet_biased_bytes(seed + rng.state, length)
}

///|
fn fuzz_roundtrip_item(seed : Int) -> @telnet.EncodeItem {
  let (r1, kind) = fuzz_rng(seed).bounded_int(4)
  let (r2, n) = r1.bounded_int(256)
  match kind {
    0 =>
      @telnet.EncodeItem::EscapedData(
        fuzz_span_suffix(seed + 101, fuzz_roundtrip_payload(seed + 201, 24)),
      )
    1 => @telnet.EncodeItem::Command(fuzz_simple_command(n))
    2 =>
      @telnet.EncodeItem::Negotiation(@telnet.NegotiationEvent::{
        verb: fuzz_negotiation_verb(n),
        option: @telnet.OptionCode::{ value: byte(r2.state % 256) },
      })
    _ =>
      @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: @telnet.OptionCode::{ value: byte(n) },
        payload: fuzz_span_suffix(
          seed + 301,
          fuzz_roundtrip_payload(seed + 401, 20),
        ),
      })
  }
}

///|
fn fuzz_encode_item_to_bytes(
  encoder : @telnet.Encoder,
  item : @telnet.EncodeItem,
  seed : Int,
) -> Bytes raise {
  let required = encoder.required_capacity(item)
  let output = Bytes::new(required)
  match encoder.encode_item(item, output) {
    Ok(result) => {
      assert_true(result.bytes_written == required)
      assert_true(result.required_capacity == required)
    }
    Err(_) => {
      println("encode roundtrip unsupported item seed=" + seed.to_string())
      abort("encode roundtrip unsupported item")
    }
  }
  output
}

///|
fn fuzz_push_expected_roundtrip_event(
  out : Array[FuzzObservedEvent],
  item : @telnet.EncodeItem,
) -> Unit {
  match item {
    @telnet.EncodeItem::EscapedData(span) =>
      fuzz_push_data_event(out, span.to_bytes())
    @telnet.EncodeItem::Command(command) =>
      out.push(FuzzObservedEvent::Command(command))
    @telnet.EncodeItem::Negotiation(event) =>
      out.push(FuzzObservedEvent::Negotiation(event))
    @telnet.EncodeItem::Subnegotiation(event) =>
      out.push(
        FuzzObservedEvent::Subnegotiation(
          event.option,
          event.payload.to_bytes(),
        ),
      )
    @telnet.EncodeItem::RawData(span) =>
      fuzz_push_data_event(out, span.to_bytes())
  }
}

///|
fn fuzz_assert_encode_parse_roundtrip(
  items : Array[@telnet.EncodeItem],
  seed : Int,
) -> Unit raise {
  let encoder = @telnet.Encoder::canonical()
  let wire_parts : Array[Byte] = []
  let expected : Array[FuzzObservedEvent] = []
  items.each(fn(item) raise {
    let encoded = fuzz_encode_item_to_bytes(encoder, item, seed)
    wire_parts.push_iter(encoded.to_array().iter())
    fuzz_push_expected_roundtrip_event(expected, item)
  })
  let wire = Bytes::from_array(wire_parts)
  let config = fuzz_roundtrip_parser_config()
  let observed = fuzz_observe_whole(config, wire)
  if !observed.complete || observed.events != expected {
    println("encode roundtrip mismatch " + fuzz_reproduction_line(seed, wire))
    println("config=" + fuzz_parser_config_summary(config))
    println("expected " + fuzz_observed_events_summary(expected))
    println("observed " + fuzz_observation_summary(observed))
    abort("encode roundtrip mismatch")
  }
}

///|
test "encoder parser roundtrip fuzz covers targeted valid frames" {
  fuzz_assert_encode_parse_roundtrip(
    [
      @telnet.EncodeItem::EscapedData(
        fuzz_span_suffix(9101, fuzz_bytes_from_ints([65, 255, 66])),
      ),
    ],
    9101,
  )
  fuzz_assert_encode_parse_roundtrip(
    [
      @telnet.EncodeItem::Command(@telnet.Command::NOP),
      @telnet.EncodeItem::Command(@telnet.Command::AYT),
    ],
    9102,
  )
  fuzz_assert_encode_parse_roundtrip(
    [
      @telnet.EncodeItem::Negotiation(@telnet.NegotiationEvent::{
        verb: @telnet.NegotiationVerb::Will,
        option: @telnet.OptionCode::{ value: byte(1) },
      }),
      @telnet.EncodeItem::Negotiation(@telnet.NegotiationEvent::{
        verb: @telnet.NegotiationVerb::Do,
        option: @telnet.OptionCode::{ value: byte(31) },
      }),
    ],
    9103,
  )
  fuzz_assert_encode_parse_roundtrip(
    [
      @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: @telnet.OptionCode::{ value: byte(31) },
        payload: fuzz_span_suffix(
          9104,
          fuzz_bytes_from_ints([0, 255, 240, 13, 0]),
        ),
      }),
    ],
    9104,
  )
  fuzz_assert_encode_parse_roundtrip(
    [
      @telnet.EncodeItem::EscapedData(
        fuzz_span_suffix(9105, fuzz_bytes_from_ints([13, 10, 255])),
      ),
      @telnet.EncodeItem::EscapedData(
        fuzz_span_suffix(9106, fuzz_bytes_from_ints([0, 255, 13])),
      ),
      @telnet.EncodeItem::Command(@telnet.Command::GA),
      @telnet.EncodeItem::Negotiation(@telnet.NegotiationEvent::{
        verb: @telnet.NegotiationVerb::Dont,
        option: @telnet.OptionCode::{ value: byte(255) },
      }),
      @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
        option: @telnet.OptionCode::{ value: byte(24) },
        payload: fuzz_span_suffix(9107, fuzz_bytes_from_ints([1, 255, 255])),
      }),
    ],
    9105,
  )
}

///|
test "encoder parser roundtrip fuzz covers generated valid streams" {
  for iteration = 0; iteration < 40; iteration = iteration + 1 {
    fuzz_assert_encode_parse_roundtrip(
      [fuzz_roundtrip_item(9200 + iteration)],
      9200 + iteration,
    )
  }
  for iteration = 0; iteration < 24; iteration = iteration + 1 {
    fuzz_assert_encode_parse_roundtrip(
      [
        fuzz_roundtrip_item(9300 + iteration * 5),
        fuzz_roundtrip_item(9301 + iteration * 5),
        fuzz_roundtrip_item(9302 + iteration * 5),
        fuzz_roundtrip_item(9303 + iteration * 5),
        fuzz_roundtrip_item(9304 + iteration * 5),
      ],
      9300 + iteration,
    )
  }
}

///|
fn fuzz_span_from_bytes(data : Bytes) -> @telnet.ByteSpan {
  @telnet.ByteSpan::{ bytes: data, start: 0, length: data.length() }
}

///|
fn fuzz_observation_has_error(observation : FuzzParseObservation) -> Bool {
  let mut found = false
  observation.events.each(fn(event) {
    match event {
      FuzzObservedEvent::Error(_) => found = true
      _ => ()
    }
  })
  found
}

///|
fn fuzz_observation_to_encode_items(
  observation : FuzzParseObservation,
) -> Array[@telnet.EncodeItem]? {
  if !observation.complete {
    return None
  }
  let items : Array[@telnet.EncodeItem] = []
  let mut encodable = true
  observation.events.each(fn(event) {
    match event {
      FuzzObservedEvent::Data(data) =>
        items.push(@telnet.EncodeItem::EscapedData(fuzz_span_from_bytes(data)))
      FuzzObservedEvent::Command(command) =>
        items.push(@telnet.EncodeItem::Command(command))
      FuzzObservedEvent::Negotiation(event) =>
        items.push(@telnet.EncodeItem::Negotiation(event))
      FuzzObservedEvent::Subnegotiation(option, payload) =>
        items.push(
          @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
            option,
            payload: fuzz_span_from_bytes(payload),
          }),
        )
      FuzzObservedEvent::Error(_) => encodable = false
    }
  })
  if encodable {
    Some(items)
  } else {
    None
  }
}

///|
fn fuzz_encode_items_to_wire(
  items : Array[@telnet.EncodeItem],
  seed : Int,
) -> Bytes raise {
  let encoder = @telnet.Encoder::canonical()
  let wire_parts : Array[Byte] = []
  items.each(fn(item) raise {
    let encoded = fuzz_encode_item_to_bytes(encoder, item, seed)
    wire_parts.push_iter(encoded.to_array().iter())
  })
  Bytes::from_array(wire_parts)
}

///|
fn fuzz_assert_parse_encode_stable(input : Bytes, seed : Int) -> Unit raise {
  let config = fuzz_roundtrip_parser_config()
  let first = fuzz_observe_whole(config, input)
  match fuzz_observation_to_encode_items(first) {
    None =>
      if first.complete && !fuzz_observation_has_error(first) {
        println(
          "parse encode stability unencodable without error " +
          fuzz_reproduction_line(seed, input),
        )
        println("config=" + fuzz_parser_config_summary(config))
        println("observed " + fuzz_observation_summary(first))
        abort("parse encode stability unexpected unencodable case")
      }
    Some(items) => {
      let wire = fuzz_encode_items_to_wire(items, seed)
      let second = fuzz_observe_whole(config, wire)
      if !second.complete || second.events != first.events {
        println(
          "parse encode stability mismatch " +
          fuzz_reproduction_line(seed, input),
        )
        println("config=" + fuzz_parser_config_summary(config))
        println("canonical_wire=bytes(" + fuzz_bytes_literal(wire) + ")")
        println("expected " + fuzz_observation_summary(first))
        println("observed " + fuzz_observation_summary(second))
        abort("parse encode stability mismatch")
      }
    }
  }
}

///|
fn fuzz_assert_parse_encode_excluded(input : Bytes, seed : Int) -> Unit {
  let config = fuzz_roundtrip_parser_config()
  let observed = fuzz_observe_whole(config, input)
  match fuzz_observation_to_encode_items(observed) {
    None =>
      if observed.complete && !fuzz_observation_has_error(observed) {
        println(
          "parse encode exclusion unencodable without error " +
          fuzz_reproduction_line(seed, input),
        )
        println("config=" + fuzz_parser_config_summary(config))
        println("observed " + fuzz_observation_summary(observed))
        abort("parse encode exclusion unexpected unencodable case")
      }
    Some(_) => {
      println(
        "parse encode exclusion unexpectedly encodable " +
        fuzz_reproduction_line(seed, input),
      )
      println("config=" + fuzz_parser_config_summary(config))
      println("observed " + fuzz_observation_summary(observed))
      abort("parse encode exclusion unexpectedly encodable")
    }
  }
}

///|
fn fuzz_repeat_byte(value : Byte, length : Int) -> Bytes {
  let out = Array::make(length, value)
  Bytes::from_array(out)
}

///|
fn fuzz_expected_iac_run(length : Int) -> FuzzParseObservation {
  let events : Array[FuzzObservedEvent] = []
  let escaped_count = length / 2
  if escaped_count > 0 {
    events.push(
      FuzzObservedEvent::Data(fuzz_repeat_byte(byte(255), escaped_count)),
    )
  }
  if length % 2 == 1 {
    events.push(
      FuzzObservedEvent::Error(@telnet.TelnetError::{
        kind: @telnet.TelnetErrorKind::IncompleteIac,
        offset: if length == 0 {
          0
        } else {
          length - 1
        },
        byte: Some(byte(255)),
        option: None,
      }),
    )
  }
  FuzzParseObservation::{ events, complete: length % 2 == 0 }
}

///|
fn fuzz_iac_case_failure_prefix(
  case_name : String,
  seed : Int,
  input : Bytes,
) -> String {
  "IAC stress case=" +
  case_name +
  " seed=" +
  seed.to_string() +
  " length=" +
  input.length().to_string() +
  " wire=" +
  fuzz_bytes_literal(input)
}

///|
fn fuzz_assert_iac_observation(
  case_name : String,
  input : Bytes,
  expected : FuzzParseObservation,
  seed : Int,
) -> Unit {
  let observed = fuzz_observe_whole(fuzz_roundtrip_parser_config(), input)
  if observed != expected {
    println(fuzz_iac_case_failure_prefix(case_name, seed, input))
    println("expected " + fuzz_observation_summary(expected))
    println("observed " + fuzz_observation_summary(observed))
    abort("IAC stress observation mismatch")
  }
}

///|
fn fuzz_assert_iac_streaming(
  case_name : String,
  input : Bytes,
  expected : FuzzParseObservation,
  seed : Int,
) -> Unit raise {
  fuzz_assert_iac_observation(case_name, input, expected, seed)
  let whole = fuzz_observe_whole(fuzz_roundtrip_parser_config(), input)
  for split = 0; split <= input.length(); split = split + 1 {
    let chunked = fuzz_observe_chunks(fuzz_roundtrip_parser_config(), input, [
      0,
      split,
      0,
      input.length() - split,
      0,
    ])
    if chunked != whole {
      println(fuzz_iac_case_failure_prefix(case_name, seed, input))
      println("split=" + split.to_string())
      println("whole " + fuzz_observation_summary(whole))
      println("chunked " + fuzz_observation_summary(chunked))
      abort("IAC stress streaming mismatch")
    }
  }
  let single = fuzz_observe_chunks(
    fuzz_roundtrip_parser_config(),
    input,
    fuzz_one_byte_chunks(input.length()),
  )
  if single != whole {
    println(fuzz_iac_case_failure_prefix(case_name, seed, input))
    println("chunks=one-byte-with-empty-feeds")
    println("whole " + fuzz_observation_summary(whole))
    println("chunked " + fuzz_observation_summary(single))
    abort("IAC stress one-byte streaming mismatch")
  }
}

///|
fn fuzz_assert_iac_encoder_case(
  case_name : String,
  item : @telnet.EncodeItem,
  expected_wire : Bytes,
  expected : FuzzParseObservation,
  seed : Int,
) -> Unit raise {
  let wire = fuzz_encode_item_to_bytes(@telnet.Encoder::canonical(), item, seed)
  if wire != expected_wire {
    println(fuzz_iac_case_failure_prefix(case_name, seed, wire))
    println("expected_wire=" + fuzz_bytes_literal(expected_wire))
    abort("IAC stress encoder wire mismatch")
  }
  fuzz_assert_iac_streaming(case_name, wire, expected, seed)
}

///|
test "IAC stress fuzz covers data escaping and repeated runs" {
  fuzz_assert_iac_encoder_case(
    "escaped-data-single-iac",
    @telnet.EncodeItem::EscapedData(
      fuzz_span_suffix(11000, fuzz_bytes_from_ints([255])),
    ),
    fuzz_bytes_from_ints([255, 255]),
    FuzzParseObservation::{
      events: [FuzzObservedEvent::Data(fuzz_bytes_from_ints([255]))],
      complete: true,
    },
    11000,
  )
  fuzz_assert_iac_encoder_case(
    "escaped-data-mixed-iac",
    @telnet.EncodeItem::EscapedData(
      fuzz_span_suffix(11001, fuzz_bytes_from_ints([65, 255, 66, 255])),
    ),
    fuzz_bytes_from_ints([65, 255, 255, 66, 255, 255]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Data(fuzz_bytes_from_ints([65, 255, 66, 255])),
      ],
      complete: true,
    },
    11001,
  )
  for length = 1; length <= 9; length = length + 1 {
    fuzz_assert_iac_streaming(
      "repeated-iac-run-" + length.to_string(),
      fuzz_repeat_byte(byte(255), length),
      fuzz_expected_iac_run(length),
      11100 + length,
    )
  }
}

///|
test "IAC stress fuzz covers subnegotiation escapes and embedded commands" {
  fuzz_assert_iac_encoder_case(
    "subnegotiation-escaped-iac-payload",
    @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: @telnet.OptionCode::{ value: byte(31) },
      payload: fuzz_span_suffix(11200, fuzz_bytes_from_ints([1, 255, 2, 255])),
    }),
    fuzz_bytes_from_ints([255, 250, 31, 1, 255, 255, 2, 255, 255, 255, 240]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Subnegotiation(
          @telnet.OptionCode::{ value: byte(31) },
          fuzz_bytes_from_ints([1, 255, 2, 255]),
        ),
      ],
      complete: true,
    },
    11200,
  )
  fuzz_assert_iac_streaming(
    "subnegotiation-embedded-iac-command-is-not-payload",
    fuzz_bytes_from_ints([255, 250, 31, 65, 255, 241, 66, 255, 240]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::InvalidCommandByte,
          offset: 5,
          byte: Some(byte(241)),
          option: None,
        }),
        FuzzObservedEvent::Subnegotiation(
          @telnet.OptionCode::{ value: byte(31) },
          fuzz_bytes_from_ints([65, 66]),
        ),
      ],
      complete: true,
    },
    11201,
  )
  fuzz_assert_iac_streaming(
    "subnegotiation-trailing-iac-is-incomplete",
    fuzz_bytes_from_ints([255, 250, 31, 65, 255]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::IncompleteSubnegotiation,
          offset: 4,
          byte: Some(byte(65)),
          option: None,
        }),
      ],
      complete: false,
    },
    11202,
  )
}

///|
test "IAC stress fuzz covers command boundaries" {
  fuzz_assert_iac_encoder_case(
    "command-after-iac-nop",
    @telnet.EncodeItem::Command(@telnet.Command::NOP),
    fuzz_bytes_from_ints([255, 241]),
    FuzzParseObservation::{
      events: [FuzzObservedEvent::Command(@telnet.Command::NOP)],
      complete: true,
    },
    11300,
  )
  fuzz_assert_iac_streaming(
    "data-command-data-with-command-byte-at-chunk-boundary",
    fuzz_bytes_from_ints([65, 255, 241, 66]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Data(fuzz_bytes_from_ints([65])),
        FuzzObservedEvent::Command(@telnet.Command::NOP),
        FuzzObservedEvent::Data(fuzz_bytes_from_ints([66])),
      ],
      complete: true,
    },
    11301,
  )
  let boundary = fuzz_observe_chunks(
    fuzz_roundtrip_parser_config(),
    fuzz_bytes_from_ints([65, 255, 241, 66]),
    [2, 1, 1],
  )
  if boundary.events !=
    [
      FuzzObservedEvent::Data(fuzz_bytes_from_ints([65])),
      FuzzObservedEvent::Command(@telnet.Command::NOP),
      FuzzObservedEvent::Data(fuzz_bytes_from_ints([66])),
    ] ||
    !boundary.complete {
    println(
      fuzz_iac_case_failure_prefix(
        "explicit-command-byte-after-iac-boundary",
        11302,
        fuzz_bytes_from_ints([65, 255, 241, 66]),
      ),
    )
    println("observed " + fuzz_observation_summary(boundary))
    abort("IAC stress explicit command boundary mismatch")
  }
}

///|
fn fuzz_subnegotiation_config(
  max_subnegotiation_bytes : Int,
) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 64,
    max_subnegotiation_bytes,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
fn fuzz_int_array_literal(items : Array[Int]) -> String {
  let mut out = "["
  for i = 0; i < items.length(); i = i + 1 {
    if i > 0 {
      out = out + ", "
    }
    out = out + items[i].to_string()
  }
  out + "]"
}

///|
fn fuzz_subnegotiation_failure_prefix(
  case_name : String,
  seed : Int,
  config : @telnet.ParserConfig,
  input : Bytes,
) -> String {
  "subnegotiation fuzz case=" +
  case_name +
  " seed=" +
  seed.to_string() +
  " length=" +
  input.length().to_string() +
  " max_subnegotiation_bytes=" +
  config.max_subnegotiation_bytes.to_string() +
  " wire=" +
  fuzz_bytes_literal(input)
}

///|
fn fuzz_assert_subnegotiation_observation(
  case_name : String,
  config : @telnet.ParserConfig,
  input : Bytes,
  expected : FuzzParseObservation,
  seed : Int,
) -> Unit {
  let observed = fuzz_observe_whole(config, input)
  if observed != expected {
    println(fuzz_subnegotiation_failure_prefix(case_name, seed, config, input))
    println("expected " + fuzz_observation_summary(expected))
    println("observed " + fuzz_observation_summary(observed))
    abort("subnegotiation fuzz observation mismatch")
  }
}

///|
fn fuzz_assert_subnegotiation_streaming_matches(
  case_name : String,
  config : @telnet.ParserConfig,
  input : Bytes,
  chunks : Array[Int],
  whole : FuzzParseObservation,
  seed : Int,
) -> Unit raise {
  let chunked = fuzz_observe_chunks(config, input, chunks)
  if chunked != whole {
    println(fuzz_subnegotiation_failure_prefix(case_name, seed, config, input))
    println("chunks=" + fuzz_int_array_literal(chunks))
    println("whole " + fuzz_observation_summary(whole))
    println("chunked " + fuzz_observation_summary(chunked))
    abort("subnegotiation fuzz streaming mismatch")
  }
}

///|
fn fuzz_assert_subnegotiation_case(
  case_name : String,
  config : @telnet.ParserConfig,
  input : Bytes,
  expected : FuzzParseObservation,
  seed : Int,
) -> Unit raise {
  fuzz_assert_parser_smoke(config, input)
  fuzz_assert_subnegotiation_observation(
    case_name, config, input, expected, seed,
  )
  let whole = fuzz_observe_whole(config, input)
  for split = 0; split <= input.length(); split = split + 1 {
    fuzz_assert_subnegotiation_streaming_matches(
      case_name,
      config,
      input,
      [0, split, 0, input.length() - split, 0],
      whole,
      seed,
    )
  }
  fuzz_assert_subnegotiation_streaming_matches(
    case_name,
    config,
    input,
    fuzz_one_byte_chunks(input.length()),
    whole,
    seed,
  )
}

///|
fn fuzz_assert_subnegotiation_safe_case(
  case_name : String,
  config : @telnet.ParserConfig,
  input : Bytes,
  seed : Int,
) -> Unit raise {
  fuzz_assert_parser_smoke(config, input)
  let whole = fuzz_observe_whole(config, input)
  fuzz_assert_subnegotiation_streaming_matches(
    case_name,
    config,
    input,
    fuzz_one_byte_chunks(input.length()),
    whole,
    seed,
  )
  for pattern = 0; pattern < 3; pattern = pattern + 1 {
    fuzz_assert_subnegotiation_streaming_matches(
      case_name,
      config,
      input,
      fuzz_random_chunks(seed + pattern * 409, input.length()),
      whole,
      seed,
    )
  }
}

///|
fn fuzz_raw_subnegotiation_wire(
  option : Byte?,
  payload : Bytes,
  closing : Bool,
) -> Bytes {
  let out : Array[Byte] = []
  out.push(byte(255))
  out.push(byte(250))
  match option {
    Some(value) => out.push(value)
    None => ()
  }
  for i = 0; i < payload.length(); i = i + 1 {
    out.push(payload[i])
  }
  if closing {
    out.push(byte(255))
    out.push(byte(240))
  }
  Bytes::from_array(out)
}

///|
fn fuzz_assert_valid_subnegotiation_frame(
  case_name : String,
  option : Byte,
  payload : Bytes,
  seed : Int,
) -> Unit raise {
  let config = fuzz_subnegotiation_config(128)
  let option_code = @telnet.OptionCode::{ value: option }
  let item = @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
    option: option_code,
    payload: fuzz_span_suffix(seed, payload),
  })
  let wire = fuzz_encode_item_to_bytes(@telnet.Encoder::canonical(), item, seed)
  fuzz_assert_subnegotiation_case(
    case_name,
    config,
    wire,
    FuzzParseObservation::{
      events: [FuzzObservedEvent::Subnegotiation(option_code, payload)],
      complete: true,
    },
    seed,
  )
}

///|
fn fuzz_generated_subnegotiation_payload(seed : Int) -> Bytes {
  let (rng, length) = fuzz_rng(seed).bounded_int(13)
  fuzz_telnet_biased_bytes(seed + rng.state, length)
}

///|
fn fuzz_generated_malformed_subnegotiation_wire(seed : Int) -> Bytes {
  let (r1, kind) = fuzz_rng(seed).bounded_int(5)
  let (r2, option) = r1.bounded_int(256)
  let (r3, extra) = r2.bounded_int(5)
  let payload = fuzz_no_iac_bytes(seed + r3.state, extra + 1)
  match kind {
    0 => fuzz_raw_subnegotiation_wire(None, Bytes::new(0), false)
    1 => fuzz_raw_subnegotiation_wire(Some(byte(option)), payload, false)
    2 => {
      let out : Array[Byte] = []
      out.push(byte(255))
      out.push(byte(250))
      out.push(byte(option))
      out.push(byte(65))
      out.push(byte(255))
      out.push(byte(241))
      out.push(byte(66))
      out.push(byte(255))
      out.push(byte(240))
      Bytes::from_array(out)
    }
    3 => {
      let out : Array[Byte] = []
      out.push(byte(255))
      out.push(byte(250))
      out.push(byte(option))
      out.push(byte(1))
      out.push(byte(255))
      out.push(byte(250))
      out.push(byte((option + 1) % 256))
      out.push(byte(255))
      out.push(byte(240))
      Bytes::from_array(out)
    }
    _ => {
      let long_payload = fuzz_no_iac_bytes(seed + 991, 9)
      fuzz_raw_subnegotiation_wire(Some(byte(option)), long_payload, true)
    }
  }
}

///|
test "subnegotiation fuzz covers valid frames and streaming boundaries" {
  fuzz_assert_valid_subnegotiation_frame(
    "valid-empty-payload",
    byte(24),
    Bytes::new(0),
    12000,
  )
  fuzz_assert_valid_subnegotiation_frame(
    "valid-escaped-iac-and-se-bytes",
    byte(31),
    fuzz_bytes_from_ints([1, 255, 240, 255, 2]),
    12001,
  )
  fuzz_assert_valid_subnegotiation_frame(
    "valid-unknown-option-255",
    byte(255),
    fuzz_bytes_from_ints([255, 0, 13, 10]),
    12002,
  )
  for iteration = 0; iteration < 20; iteration = iteration + 1 {
    let (rng, option) = fuzz_rng(12100 + iteration).bounded_int(256)
    fuzz_assert_valid_subnegotiation_frame(
      "generated-valid-" + iteration.to_string(),
      byte(option),
      fuzz_generated_subnegotiation_payload(12100 + iteration + rng.state),
      12100 + iteration,
    )
  }
}

///|
test "subnegotiation fuzz covers malformed frames and oversized discard" {
  let config = fuzz_subnegotiation_config(128)
  fuzz_assert_subnegotiation_case(
    "missing-option-after-sb",
    config,
    fuzz_bytes_from_ints([255, 250]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::IncompleteSubnegotiation,
          offset: 1,
          byte: None,
          option: None,
        }),
      ],
      complete: false,
    },
    12200,
  )
  fuzz_assert_subnegotiation_case(
    "missing-se-after-payload",
    config,
    fuzz_bytes_from_ints([255, 250, 31, 65, 66]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::IncompleteSubnegotiation,
          offset: 4,
          byte: Some(byte(66)),
          option: None,
        }),
      ],
      complete: false,
    },
    12201,
  )
  fuzz_assert_subnegotiation_case(
    "missing-se-after-escaped-iac",
    config,
    fuzz_bytes_from_ints([255, 250, 31, 65, 255, 255, 66]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::IncompleteSubnegotiation,
          offset: 6,
          byte: Some(byte(66)),
          option: None,
        }),
      ],
      complete: false,
    },
    12202,
  )
  fuzz_assert_subnegotiation_case(
    "embedded-command-is-reported-and-omitted",
    config,
    fuzz_bytes_from_ints([255, 250, 31, 65, 255, 241, 66, 255, 240]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::InvalidCommandByte,
          offset: 5,
          byte: Some(byte(241)),
          option: None,
        }),
        FuzzObservedEvent::Subnegotiation(
          @telnet.OptionCode::{ value: byte(31) },
          fuzz_bytes_from_ints([65, 66]),
        ),
      ],
      complete: true,
    },
    12203,
  )
  fuzz_assert_subnegotiation_case(
    "nested-sb-marker-is-reported-and-omitted",
    config,
    fuzz_bytes_from_ints([255, 250, 31, 1, 255, 250, 2, 255, 240]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::InvalidCommandByte,
          offset: 5,
          byte: Some(byte(250)),
          option: None,
        }),
        FuzzObservedEvent::Subnegotiation(
          @telnet.OptionCode::{ value: byte(31) },
          fuzz_bytes_from_ints([1, 2]),
        ),
      ],
      complete: true,
    },
    12204,
  )
  fuzz_assert_subnegotiation_case(
    "oversized-payload-discards-until-se-then-resumes",
    fuzz_subnegotiation_config(3),
    fuzz_bytes_from_ints([255, 250, 31, 1, 2, 3, 4, 5, 255, 240, 65]),
    FuzzParseObservation::{
      events: [
        FuzzObservedEvent::Error(@telnet.TelnetError::{
          kind: @telnet.TelnetErrorKind::SubnegotiationTooLarge,
          offset: 6,
          byte: Some(byte(4)),
          option: None,
        }),
        FuzzObservedEvent::Data(fuzz_bytes_from_ints([65])),
      ],
      complete: true,
    },
    12205,
  )
  for iteration = 0; iteration < 20; iteration = iteration + 1 {
    fuzz_assert_subnegotiation_safe_case(
      "generated-malformed-" + iteration.to_string(),
      fuzz_subnegotiation_config(4 + iteration % 5),
      fuzz_generated_malformed_subnegotiation_wire(12300 + iteration),
      12300 + iteration,
    )
  }
}

///|
fn fuzz_policy_decision(choice : Int) -> @telnet.PolicyDecision {
  match choice % 3 {
    0 => @telnet.PolicyDecision::Accept
    1 => @telnet.PolicyDecision::Reject
    _ => @telnet.PolicyDecision::Ignore
  }
}

///|
fn fuzz_known_option_byte(choice : Int) -> Byte {
  let known = [0, 1, 3, 24, 31, 34, 39, 42, 46, 255]
  byte(known[choice % known.length()])
}

///|
fn fuzz_unknown_option_byte(choice : Int) -> Byte {
  let unknown = [7, 23, 41, 47, 50, 91, 137, 200, 254]
  byte(unknown[choice % unknown.length()])
}

///|
fn fuzz_negotiation_option(choice : Int, fallback : Byte) -> @telnet.OptionCode {
  let option = match choice % 4 {
    0 | 1 => fuzz_known_option_byte(choice / 4)
    2 => fuzz_unknown_option_byte(choice / 4)
    _ => fallback
  }
  @telnet.OptionCode::{ value: option }
}

///|
fn fuzz_generated_negotiation_event(
  rng : FuzzRng,
) -> (FuzzRng, @telnet.NegotiationEvent) {
  let (r1, verb_choice) = rng.bounded_int(4)
  let (r2, option_choice) = r1.bounded_int(64)
  let (r3, fallback) = r2.byte()
  (
    r3,
    @telnet.NegotiationEvent::{
      verb: fuzz_negotiation_verb(verb_choice),
      option: fuzz_negotiation_option(option_choice, fallback),
    },
  )
}

///|
fn fuzz_generated_policy_decision(
  rng : FuzzRng,
) -> (FuzzRng, @telnet.PolicyDecision) {
  let (next, choice) = rng.bounded_int(3)
  (next, fuzz_policy_decision(choice))
}

///|
fn fuzz_generated_option_side(rng : FuzzRng) -> (FuzzRng, @telnet.OptionSide) {
  let (next, choice) = rng.bounded_int(2)
  (
    next,
    if choice == 0 {
      @telnet.OptionSide::Local
    } else {
      @telnet.OptionSide::Remote
    },
  )
}

///|
fn fuzz_negotiation_event_wire(event : @telnet.NegotiationEvent) -> Bytes {
  fuzz_bytes_from_ints([
    255,
    event.verb.to_command().to_byte().to_int(),
    event.option.value.to_int(),
  ])
}

///|
fn fuzz_policy_decision_name(decision : @telnet.PolicyDecision) -> String {
  match decision {
    @telnet.PolicyDecision::Accept => "Accept"
    @telnet.PolicyDecision::Reject => "Reject"
    @telnet.PolicyDecision::Ignore => "Ignore"
  }
}

///|
fn fuzz_option_side_name(side : @telnet.OptionSide) -> String {
  match side {
    @telnet.OptionSide::Local => "Local"
    @telnet.OptionSide::Remote => "Remote"
  }
}

///|
fn fuzz_queue_bit_summary(bit : @telnet.QueueBit) -> String {
  match bit {
    @telnet.QueueBit::Empty => "Empty"
    @telnet.QueueBit::Opposite => "Opposite"
  }
}

///|
fn fuzz_half_state_summary(state : @telnet.HalfState) -> String {
  match state {
    @telnet.HalfState::No => "No"
    @telnet.HalfState::Yes => "Yes"
    @telnet.HalfState::WantNo(bit) =>
      "WantNo(" + fuzz_queue_bit_summary(bit) + ")"
    @telnet.HalfState::WantYes(bit) =>
      "WantYes(" + fuzz_queue_bit_summary(bit) + ")"
  }
}

///|
fn fuzz_option_code_summary(code : @telnet.OptionCode) -> String {
  code.value.to_int().to_string()
}

///|
fn fuzz_option_state_summary(state : @telnet.OptionState) -> String {
  "OptionState(option=" +
  fuzz_option_code_summary(state.option) +
  ", local=" +
  fuzz_half_state_summary(state.local_state) +
  ", remote=" +
  fuzz_half_state_summary(state.remote_state) +
  ")"
}

///|
fn fuzz_negotiation_event_summary(event : @telnet.NegotiationEvent) -> String {
  fuzz_negotiation_verb_name(event.verb) +
  " " +
  fuzz_option_code_summary(event.option)
}

///|
fn fuzz_negotiation_action_summary(
  action : @telnet.NegotiationAction,
) -> String {
  match action {
    @telnet.NegotiationAction::Send(event) =>
      "Send(" + fuzz_negotiation_event_summary(event) + ")"
    @telnet.NegotiationAction::MarkEnabled(side, option) =>
      "MarkEnabled(" +
      fuzz_option_side_name(side) +
      ", " +
      fuzz_option_code_summary(option) +
      ")"
    @telnet.NegotiationAction::MarkDisabled(side, option) =>
      "MarkDisabled(" +
      fuzz_option_side_name(side) +
      ", " +
      fuzz_option_code_summary(option) +
      ")"
    @telnet.NegotiationAction::NotifyApplication(state) =>
      "NotifyApplication(" + fuzz_option_state_summary(state) + ")"
    @telnet.NegotiationAction::NoAction => "NoAction"
  }
}

///|
fn fuzz_negotiation_actions_summary(
  actions : Array[@telnet.NegotiationAction],
) -> String {
  let mut out = "["
  for i = 0; i < actions.length(); i = i + 1 {
    if i > 0 {
      out = out + ", "
    }
    out = out + fuzz_negotiation_action_summary(actions[i])
  }
  out + "]"
}

///|
fn fuzz_negotiation_transition_summary(
  transition : @telnet.NegotiationTransition,
) -> String {
  "Transition(before=" +
  fuzz_option_state_summary(transition.before) +
  ", input=" +
  fuzz_negotiation_event_summary(transition.input) +
  ", decision=" +
  fuzz_policy_decision_name(transition.decision) +
  ", after=" +
  fuzz_option_state_summary(transition.after) +
  ", actions=" +
  fuzz_negotiation_actions_summary(transition.actions) +
  ")"
}

///|
fn fuzz_option_states_summary(states : Array[@telnet.OptionState]) -> String {
  let mut out = "["
  for i = 0; i < states.length(); i = i + 1 {
    if i > 0 {
      out = out + ", "
    }
    out = out + fuzz_option_state_summary(states[i])
  }
  out + "]"
}

///|
fn fuzz_negotiation_failure_prefix(
  case_name : String,
  seed : Int,
  iteration : Int,
  sequence_length : Int,
  step : Int,
) -> String {
  "negotiator fuzz case=" +
  case_name +
  " seed=" +
  seed.to_string() +
  " iteration=" +
  iteration.to_string() +
  " sequence_length=" +
  sequence_length.to_string() +
  " step=" +
  step.to_string()
}

///|
fn fuzz_print_negotiation_failure(
  case_name : String,
  seed : Int,
  iteration : Int,
  sequence_length : Int,
  step : Int,
  operation : String,
  transition : @telnet.NegotiationTransition,
) -> Unit {
  println(
    fuzz_negotiation_failure_prefix(
      case_name, seed, iteration, sequence_length, step,
    ),
  )
  println("operation=" + operation)
  println(
    "wire=" + fuzz_bytes_literal(fuzz_negotiation_event_wire(transition.input)),
  )
  println("transition=" + fuzz_negotiation_transition_summary(transition))
}

///|
fn fuzz_assert_negotiation_actions_bounded(
  case_name : String,
  seed : Int,
  iteration : Int,
  sequence_length : Int,
  step : Int,
  operation : String,
  transition : @telnet.NegotiationTransition,
) -> Unit {
  if transition.actions.length() > 2 {
    fuzz_print_negotiation_failure(
      case_name, seed, iteration, sequence_length, step, operation, transition,
    )
    abort("negotiator fuzz action amplification")
  }
  for action in transition.actions {
    match action {
      @telnet.NegotiationAction::Send(event) =>
        if event.option != transition.input.option {
          fuzz_print_negotiation_failure(
            case_name, seed, iteration, sequence_length, step, operation, transition,
          )
          println("send_action=" + fuzz_negotiation_event_summary(event))
          abort("negotiator fuzz send option drift")
        }
      @telnet.NegotiationAction::MarkEnabled(_, option)
      | @telnet.NegotiationAction::MarkDisabled(_, option) =>
        if option != transition.input.option {
          fuzz_print_negotiation_failure(
            case_name, seed, iteration, sequence_length, step, operation, transition,
          )
          println("mark_option=" + fuzz_option_code_summary(option))
          abort("negotiator fuzz mark option drift")
        }
      @telnet.NegotiationAction::NotifyApplication(state) =>
        if state.option != transition.input.option {
          fuzz_print_negotiation_failure(
            case_name, seed, iteration, sequence_length, step, operation, transition,
          )
          println("notify_state=" + fuzz_option_state_summary(state))
          abort("negotiator fuzz notify option drift")
        }
      @telnet.NegotiationAction::NoAction => ()
    }
  }
}

///|
fn fuzz_assert_negotiator_state_lookup(
  case_name : String,
  seed : Int,
  iteration : Int,
  sequence_length : Int,
  step : Int,
  operation : String,
  negotiator : @telnet.Negotiator,
  transition : @telnet.NegotiationTransition,
) -> Unit {
  let observed = negotiator.state_for(transition.after.option)
  if observed != transition.after {
    fuzz_print_negotiation_failure(
      case_name, seed, iteration, sequence_length, step, operation, transition,
    )
    println("observed_state=" + fuzz_option_state_summary(observed))
    abort("negotiator fuzz state lookup mismatch")
  }
}

///|
fn fuzz_assert_negotiator_unique_states(
  case_name : String,
  seed : Int,
  iteration : Int,
  sequence_length : Int,
  step : Int,
  operation : String,
  negotiator : @telnet.Negotiator,
  transition : @telnet.NegotiationTransition,
) -> Unit {
  for i = 0; i < negotiator.states.length(); i = i + 1 {
    for j = i + 1; j < negotiator.states.length(); j = j + 1 {
      if negotiator.states[i].option == negotiator.states[j].option {
        fuzz_print_negotiation_failure(
          case_name, seed, iteration, sequence_length, step, operation, transition,
        )
        println("states=" + fuzz_option_states_summary(negotiator.states))
        abort("negotiator fuzz duplicate option states")
      }
    }
  }
}

///|
fn fuzz_apply_and_assert_negotiator_transition(
  case_name : String,
  seed : Int,
  iteration : Int,
  sequence_length : Int,
  step : Int,
  operation : String,
  negotiator : @telnet.Negotiator,
  transition : @telnet.NegotiationTransition,
) -> @telnet.Negotiator {
  fuzz_assert_negotiation_actions_bounded(
    case_name, seed, iteration, sequence_length, step, operation, transition,
  )
  let next = negotiator.apply(transition)
  fuzz_assert_negotiator_state_lookup(
    case_name, seed, iteration, sequence_length, step, operation, next, transition,
  )
  fuzz_assert_negotiator_unique_states(
    case_name, seed, iteration, sequence_length, step, operation, next, transition,
  )
  next
}

///|
fn fuzz_assert_negotiator_sequence(
  case_name : String,
  seed : Int,
  iteration : Int,
  sequence_length : Int,
) -> Unit {
  let mut rng = fuzz_rng(seed)
  let mut negotiator = @telnet.Negotiator::new()
  for step = 0; step < sequence_length; step = step + 1 {
    let (r1, event) = fuzz_generated_negotiation_event(rng)
    let (r2, decision) = fuzz_generated_policy_decision(r1)
    let transition = negotiator.receive(event, decision)
    negotiator = fuzz_apply_and_assert_negotiator_transition(
      case_name,
      seed,
      iteration,
      sequence_length,
      step,
      "receive decision=" + fuzz_policy_decision_name(decision),
      negotiator,
      transition,
    )
    rng = r2
  }
}

///|
fn fuzz_assert_negotiator_interleaved_sequence(
  case_name : String,
  seed : Int,
  iteration : Int,
  sequence_length : Int,
) -> Unit {
  let mut rng = fuzz_rng(seed)
  let mut negotiator = @telnet.Negotiator::new()
  for step = 0; step < sequence_length; step = step + 1 {
    let (r0, mode) = rng.bounded_int(3)
    if mode == 0 {
      let (r1, option_choice) = r0.bounded_int(64)
      let (r2, fallback) = r1.byte()
      let (r3, side) = fuzz_generated_option_side(r2)
      let (r4, enable) = r3.bool()
      let option = fuzz_negotiation_option(option_choice, fallback)
      let transition = negotiator.request(option, side, enable)
      negotiator = fuzz_apply_and_assert_negotiator_transition(
        case_name,
        seed,
        iteration,
        sequence_length,
        step,
        "request side=" +
        fuzz_option_side_name(side) +
        " enable=" +
        enable.to_string(),
        negotiator,
        transition,
      )
      rng = r4
    } else {
      let (r1, event) = fuzz_generated_negotiation_event(r0)
      let (r2, decision) = fuzz_generated_policy_decision(r1)
      let transition = negotiator.receive(event, decision)
      negotiator = fuzz_apply_and_assert_negotiator_transition(
        case_name,
        seed,
        iteration,
        sequence_length,
        step,
        "receive decision=" + fuzz_policy_decision_name(decision),
        negotiator,
        transition,
      )
      rng = r2
    }
  }
}

///|
test "negotiator fuzz covers generated command sequences" {
  // Invariants: generated WILL/WONT/DO/DONT sequences must not panic, each
  // transition emits at most two actions, any emitted action stays scoped to the
  // input option, and apply/state_for keeps one latest state per option.
  for iteration = 0; iteration < 32; iteration = iteration + 1 {
    fuzz_assert_negotiator_sequence(
      "incoming-generated-" + iteration.to_string(),
      13000 + iteration,
      iteration,
      1 + iteration * 5 % 41,
    )
  }
}

///|
test "negotiator fuzz covers interleaved local requests and peer commands" {
  // Interleaving local request() calls with peer receive() events covers the
  // same bounded-output and state uniqueness invariants while exercising
  // loop-prevention paths for duplicate and opposite queued requests.
  for iteration = 0; iteration < 24; iteration = iteration + 1 {
    fuzz_assert_negotiator_interleaved_sequence(
      "interleaved-generated-" + iteration.to_string(),
      13100 + iteration,
      iteration,
      2 + iteration * 7 % 37,
    )
  }
}

///|
test "parse encode stability fuzz covers targeted valid streams" {
  fuzz_assert_parse_encode_stable(fuzz_bytes_from_ints([]), 10100)
  fuzz_assert_parse_encode_stable(
    fuzz_bytes_from_ints([72, 101, 108, 108, 111]),
    10101,
  )
  fuzz_assert_parse_encode_stable(
    fuzz_bytes_from_ints([65, 255, 255, 66]),
    10102,
  )
  fuzz_assert_parse_encode_stable(
    fuzz_bytes_from_ints([255, 241, 255, 246]),
    10103,
  )
  fuzz_assert_parse_encode_stable(
    fuzz_bytes_from_ints([255, 251, 1, 255, 253, 31]),
    10104,
  )
  fuzz_assert_parse_encode_stable(
    fuzz_bytes_from_ints([255, 250, 31, 0, 255, 255, 240, 13, 0, 255, 240]),
    10105,
  )
}

///|
test "parse encode stability fuzz documents excluded malformed tails" {
  fuzz_assert_parse_encode_excluded(fuzz_bytes_from_ints([255]), 10200)
  fuzz_assert_parse_encode_excluded(fuzz_bytes_from_ints([255, 251]), 10201)
  fuzz_assert_parse_encode_excluded(fuzz_bytes_from_ints([255, 250]), 10202)
  fuzz_assert_parse_encode_excluded(
    fuzz_bytes_from_ints([255, 250, 31, 255]),
    10203,
  )
  fuzz_assert_parse_encode_excluded(fuzz_bytes_from_ints([255, 240]), 10204)
  fuzz_assert_parse_encode_excluded(fuzz_bytes_from_ints([255, 1]), 10205)
}

///|
test "parse encode stability fuzz covers generated arbitrary streams" {
  for iteration = 0; iteration < 32; iteration = iteration + 1 {
    let no_iac_length = iteration * 7 % 49
    fuzz_assert_parse_encode_stable(
      fuzz_no_iac_bytes(10300 + iteration, no_iac_length),
      10300 + iteration,
    )
    let dense_length = (iteration * 9 + 1) % 57
    fuzz_assert_parse_encode_stable(
      fuzz_telnet_biased_bytes(10400 + iteration, dense_length),
      10400 + iteration,
    )
  }
}

///|
struct FuzzSeedCorpusCase {
  name : String
  seed : Int
  wire : Bytes
  parse_encode_stable : Bool
} derive(Debug)

///|
fn fuzz_seed_corpus_case(
  name : String,
  seed : Int,
  wire : Bytes,
  parse_encode_stable : Bool,
) -> FuzzSeedCorpusCase {
  FuzzSeedCorpusCase::{ name, seed, wire, parse_encode_stable }
}

///|
fn fuzz_rfc_inspired_seed_corpus() -> Array[FuzzSeedCorpusCase] {
  [
    fuzz_seed_corpus_case(
      "rfc854-data-hello",
      15000,
      fuzz_bytes_from_ints([72, 101, 108, 108, 111]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc854-escaped-iac-data",
      15001,
      fuzz_bytes_from_ints([65, 255, 255, 66]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc854-simple-command-nop-ga",
      15002,
      fuzz_bytes_from_ints([255, 241, 255, 249]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc854-simple-command-ip-ao-ayt",
      15003,
      fuzz_bytes_from_ints([255, 244, 255, 245, 255, 246]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc854-will-echo",
      15004,
      fuzz_bytes_from_ints([255, 251, 1]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc854-do-suppress-go-ahead",
      15005,
      fuzz_bytes_from_ints([255, 253, 3]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc854-wont-echo-dont-suppress-go-ahead",
      15006,
      fuzz_bytes_from_ints([255, 252, 1, 255, 254, 3]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc854-login-negotiation-command-mix",
      15007,
      fuzz_bytes_from_ints([
        108, 111, 103, 105, 110, 58, 32, 255, 251, 1, 255, 253, 3, 255, 241,
      ]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc854-incomplete-iac-tail",
      15008,
      fuzz_bytes_from_ints([255]),
      false,
    ),
    fuzz_seed_corpus_case(
      "rfc854-incomplete-negotiation-tail",
      15009,
      fuzz_bytes_from_ints([255, 251]),
      false,
    ),
    fuzz_seed_corpus_case(
      "rfc854-incomplete-subnegotiation-tail",
      15010,
      fuzz_bytes_from_ints([255, 250, 31, 0, 80]),
      false,
    ),
    fuzz_seed_corpus_case(
      "rfc1073-naws-80x24",
      15011,
      fuzz_bytes_from_ints([255, 250, 31, 0, 80, 0, 24, 255, 240]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc1091-terminal-type-send",
      15012,
      fuzz_bytes_from_ints([255, 250, 24, 1, 255, 240]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc1091-terminal-type-is-vt100",
      15013,
      fuzz_bytes_from_ints([255, 250, 24, 0, 86, 84, 49, 48, 48, 255, 240]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc1572-new-environ-empty-is",
      15014,
      fuzz_bytes_from_ints([255, 250, 39, 0, 255, 240]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc2066-charset-request-utf8",
      15015,
      fuzz_bytes_from_ints([255, 250, 42, 1, 32, 85, 84, 70, 45, 56, 255, 240]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc1184-linemode-mode-edit-trapsig",
      15016,
      fuzz_bytes_from_ints([255, 250, 34, 1, 3, 255, 240]),
      true,
    ),
    fuzz_seed_corpus_case(
      "rfc2946-start-tls-do-will",
      15017,
      fuzz_bytes_from_ints([255, 253, 46, 255, 251, 46]),
      true,
    ),
    fuzz_seed_corpus_case(
      "private-option-negotiation-sample",
      15018,
      fuzz_bytes_from_ints([255, 251, 93, 255, 253, 93]),
      true,
    ),
    fuzz_seed_corpus_case(
      "strict-invalid-command-sample",
      15019,
      fuzz_bytes_from_ints([65, 255, 1, 66]),
      false,
    ),
  ]
}

///|
fn fuzz_seed_corpus_failure_prefix(
  phase : String,
  case : FuzzSeedCorpusCase,
  config_index : Int,
) -> String {
  "seed corpus fuzz phase=" +
  phase +
  " name=" +
  case.name +
  " seed=" +
  case.seed.to_string() +
  " config_index=" +
  config_index.to_string() +
  " length=" +
  case.wire.length().to_string() +
  " wire=" +
  fuzz_bytes_literal(case.wire)
}

///|
fn fuzz_print_seed_corpus_observation_failure(
  phase : String,
  case : FuzzSeedCorpusCase,
  config_index : Int,
  expected : FuzzParseObservation,
  observed : FuzzParseObservation,
) -> Unit {
  println(fuzz_seed_corpus_failure_prefix(phase, case, config_index))
  println("expected " + fuzz_observation_summary(expected))
  println("observed " + fuzz_observation_summary(observed))
}

///|
fn fuzz_assert_seed_corpus_smoke(
  case : FuzzSeedCorpusCase,
  config : @telnet.ParserConfig,
  config_index : Int,
) -> Unit {
  let fed = @telnet.Parser::new(config).feed(case.wire)
  let fed_checkpoint = fed.parser.checkpoint()
  let finished = fed.parser.finish()
  let reset_checkpoint = finished.parser.checkpoint()
  if fed.bytes_consumed != case.wire.length() ||
    fed_checkpoint.absolute_offset != case.wire.length() ||
    fed_checkpoint.buffered_data_length < 0 ||
    fed_checkpoint.buffered_subnegotiation_length < 0 ||
    fed.events.length() > case.wire.length() + 1 ||
    finished.events.length() > 1 ||
    reset_checkpoint.mode != @telnet.ParserMode::Normal ||
    reset_checkpoint.absolute_offset != 0 ||
    reset_checkpoint.buffered_data_length != 0 ||
    reset_checkpoint.buffered_subnegotiation_length != 0 {
    println(fuzz_seed_corpus_failure_prefix("smoke", case, config_index))
    println(
      "bytes_consumed=" +
      fed.bytes_consumed.to_string() +
      " fed_checkpoint_offset=" +
      fed_checkpoint.absolute_offset.to_string() +
      " fed_events=" +
      fed.events.length().to_string() +
      " finished_events=" +
      finished.events.length().to_string() +
      " reset_offset=" +
      reset_checkpoint.absolute_offset.to_string(),
    )
    abort("seed corpus smoke invariant mismatch")
  }
}

///|
fn fuzz_assert_seed_corpus_streaming(
  case : FuzzSeedCorpusCase,
  config : @telnet.ParserConfig,
  config_index : Int,
) -> Unit raise {
  let whole = fuzz_observe_whole(config, case.wire)
  let single = fuzz_observe_chunks(
    config,
    case.wire,
    fuzz_one_byte_chunks(case.wire.length()),
  )
  if single != whole {
    fuzz_print_seed_corpus_observation_failure(
      "streaming-one-byte", case, config_index, whole, single,
    )
    println("chunks=one-byte-with-empty-feeds")
    abort("seed corpus one-byte streaming mismatch")
  }
  for split = 0; split <= case.wire.length(); split = split + 1 {
    let split_observed = fuzz_observe_chunks(config, case.wire, [
      0,
      split,
      0,
      case.wire.length() - split,
      0,
    ])
    if split_observed != whole {
      fuzz_print_seed_corpus_observation_failure(
        "streaming-split", case, config_index, whole, split_observed,
      )
      println("split=" + split.to_string())
      abort("seed corpus split streaming mismatch")
    }
  }
  for pattern = 0; pattern < 3; pattern = pattern + 1 {
    let chunk_seed = case.seed + pattern * 769
    let chunked = fuzz_observe_chunks(
      config,
      case.wire,
      fuzz_random_chunks(chunk_seed, case.wire.length()),
    )
    if chunked != whole {
      fuzz_print_seed_corpus_observation_failure(
        "streaming-random", case, config_index, whole, chunked,
      )
      println(
        "pattern=" +
        pattern.to_string() +
        " chunk_seed=" +
        chunk_seed.to_string(),
      )
      abort("seed corpus random streaming mismatch")
    }
  }
}

///|
fn fuzz_assert_seed_corpus_parse_encode_stable(
  case : FuzzSeedCorpusCase,
) -> Unit raise {
  let first = fuzz_observe_whole(fuzz_roundtrip_parser_config(), case.wire)
  match fuzz_observation_to_encode_items(first) {
    None =>
      if case.parse_encode_stable {
        println(
          fuzz_seed_corpus_failure_prefix("parse-encode-unencodable", case, 0),
        )
        println("observed " + fuzz_observation_summary(first))
        abort("seed corpus expected encodable stable case")
      } else {
        assert_true(!first.complete || fuzz_observation_has_error(first))
      }
    Some(items) => {
      if !case.parse_encode_stable {
        println(
          fuzz_seed_corpus_failure_prefix("parse-encode-exclusion", case, 0),
        )
        println("observed " + fuzz_observation_summary(first))
        abort("seed corpus unexpectedly encodable excluded case")
      }
      let canonical_wire = fuzz_encode_items_to_wire(items, case.seed)
      let second = fuzz_observe_whole(
        fuzz_roundtrip_parser_config(),
        canonical_wire,
      )
      if !second.complete || second.events != first.events {
        fuzz_print_seed_corpus_observation_failure(
          "parse-encode-stability", case, 0, first, second,
        )
        println("canonical_wire=" + fuzz_bytes_literal(canonical_wire))
        abort("seed corpus parse encode stability mismatch")
      }
    }
  }
}

///|
test "RFC-inspired seed corpus fuzz covers parser streaming and stability" {
  let corpus = fuzz_rfc_inspired_seed_corpus()
  assert_true(corpus.length() == 20)
  for case in corpus {
    for config_index = 0; config_index < 5; config_index = config_index + 1 {
      let config = fuzz_parser_config(config_index)
      fuzz_assert_seed_corpus_smoke(case, config, config_index)
      fuzz_assert_seed_corpus_streaming(case, config, config_index)
    }
    fuzz_assert_seed_corpus_parse_encode_stable(case)
  }
}
