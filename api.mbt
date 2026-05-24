// Public API implementation for the TELNET core.

///|
pub(all) struct Parser {
  config : ParserConfig
  checkpoint : ParserCheckpoint
} derive(Eq, Debug)

///|
pub(all) struct ParserFeedResult {
  parser : Parser
  events : Array[Event]
  bytes_consumed : Int
} derive(Eq, Debug)

///|
pub(all) struct ParserFinishResult {
  parser : Parser
  events : Array[Event]
  complete : Bool
} derive(Eq, Debug)

///|
fn b(n : Int) -> Byte { n.to_byte() }

///|
fn unsafe_bytes_to_fixedarray(bytes : Bytes) -> FixedArray[Byte] = "%identity"

///|
fn setb(bytes : Bytes, index : Int, value : Byte) -> Unit {
  unsafe_bytes_to_fixedarray(bytes)[index] = value
}

///|
fn span_from_array(xs : Array[Byte]) -> ByteSpan {
  let bs = Bytes::from_array(xs)
  ByteSpan::{ bytes: bs, start: 0, length: bs.length() }
}

///|
fn empty_checkpoint() -> ParserCheckpoint {
  ParserCheckpoint::{
    mode: ParserMode::Normal,
    absolute_offset: 0,
    buffered_data_length: 0,
    buffered_subnegotiation_length: 0,
  }
}

///|
pub fn Parser::default_config() -> ParserConfig {
  ParserConfig::{
    max_data_chunk_bytes: 8192,
    max_subnegotiation_bytes: 8192,
    cr_policy: CrPolicy::Preserve,
    data_coalescing: DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
pub fn Parser::new(config : ParserConfig) -> Parser {
  let fixed = ParserConfig::{
    max_data_chunk_bytes: if config.max_data_chunk_bytes < 0 { 0 } else { config.max_data_chunk_bytes },
    max_subnegotiation_bytes: if config.max_subnegotiation_bytes < 0 { 0 } else { config.max_subnegotiation_bytes },
    cr_policy: config.cr_policy,
    data_coalescing: config.data_coalescing,
    strict_commands: config.strict_commands,
  }
  Parser::{ config: fixed, checkpoint: empty_checkpoint() }
}

///|
pub fn Parser::default() -> Parser { Parser::new(Parser::default_config()) }

///|
fn err_event(kind : TelnetErrorKind, offset : Int, byte : Byte?, option : OptionCode?) -> Event {
  Event::Error(TelnetError::{ kind, offset, byte, option })
}

///|
fn data_event(xs : Array[Byte]) -> Event {
  Event::Data(DataEvent::{ span: span_from_array(xs) })
}

///|
fn flush_data(data : Array[Byte], events : Array[Event]) -> Unit {
  if data.length() > 0 {
    events.push(data_event(data.copy()))
    data.clear()
  }
}

///|
pub fn Parser::feed(self : Parser, chunk : Bytes) -> ParserFeedResult {
  self.feed_span(ByteSpan::{ bytes: chunk, start: 0, length: chunk.length() })
}

///|
pub fn Parser::feed_span(self : Parser, span : ByteSpan) -> ParserFeedResult {
  let events = Array::new()
  let data = Array::new()
  let sub = Array::new()
  let mut mode = self.checkpoint.mode
  let mut i = 0
  while i < span.length {
    let absolute = self.checkpoint.absolute_offset + i
    let byte = span.bytes[span.start + i]
    match mode {
      ParserMode::Normal =>
        if byte == b(255) {
          flush_data(data, events)
          mode = ParserMode::AfterIac
        } else {
          if self.config.max_data_chunk_bytes == 0 {
            events.push(err_event(TelnetErrorKind::PolicyRejected, absolute, Some(byte), None))
          } else if self.config.cr_policy == CrPolicy::ValidateNvt && byte == b(13) && i + 1 < span.length && span.bytes[span.start + i + 1] != b(10) && span.bytes[span.start + i + 1] != b(0) {
            events.push(err_event(TelnetErrorKind::PolicyRejected, absolute + 1, Some(span.bytes[span.start + i + 1]), None))
          } else if self.config.cr_policy == CrPolicy::NormalizeToLf && byte == b(13) && i + 1 < span.length && span.bytes[span.start + i + 1] == b(10) {
            data.push(b(10)); i = i + 1; flush_data(data, events)
          } else if self.config.cr_policy == CrPolicy::NormalizeToLf && byte == b(13) && i + 1 < span.length && span.bytes[span.start + i + 1] == b(0) {
            data.push(b(13)); i = i + 1; flush_data(data, events)
          } else {
            data.push(byte)
            if self.config.data_coalescing == DataCoalescing::EmitImmediately || data.length() >= self.config.max_data_chunk_bytes {
              flush_data(data, events)
            }
          }
        }
      ParserMode::AfterIac =>
        if byte == b(255) {
          data.push(b(255))
          flush_data(data, events)
          mode = ParserMode::Normal
        } else {
          match Command::from_byte(byte) {
            Some(Command::WILL) => mode = ParserMode::AfterNegotiationVerb(NegotiationVerb::Will)
            Some(Command::WONT) => mode = ParserMode::AfterNegotiationVerb(NegotiationVerb::Wont)
            Some(Command::DO) => mode = ParserMode::AfterNegotiationVerb(NegotiationVerb::Do)
            Some(Command::DONT) => mode = ParserMode::AfterNegotiationVerb(NegotiationVerb::Dont)
            Some(Command::SB) => mode = ParserMode::AfterSubnegotiationStart
            Some(Command::SE) => {
              events.push(err_event(TelnetErrorKind::UnexpectedSubnegotiationEnd, absolute, Some(byte), None))
              mode = ParserMode::Normal
            }
            Some(c) => {
              events.push(Event::Command(CommandEvent::{ command: c }))
              mode = ParserMode::Normal
            }
            None => {
              events.push(err_event(TelnetErrorKind::InvalidCommandByte, absolute, Some(byte), None))
              mode = ParserMode::Normal
            }
          }
        }
      ParserMode::AfterNegotiationVerb(v) => {
        events.push(Event::Negotiation(NegotiationEvent::{ verb: v, option: OptionCode::{ value: byte } }))
        mode = ParserMode::Normal
      }
      ParserMode::AfterSubnegotiationStart => {
        sub.clear()
        mode = ParserMode::InSubnegotiation(OptionCode::{ value: byte })
      }
      ParserMode::InSubnegotiation(opt) =>
        if byte == b(255) {
          mode = ParserMode::InSubnegotiationAfterIac(opt)
        } else {
          sub.push(byte)
          if sub.length() > self.config.max_subnegotiation_bytes {
            events.push(err_event(TelnetErrorKind::SubnegotiationTooLarge, absolute, Some(byte), Some(opt)))
            sub.clear()
            mode = ParserMode::Normal
          }
        }
      ParserMode::InSubnegotiationAfterIac(opt) =>
        if byte == b(255) {
          sub.push(b(255))
          if sub.length() > self.config.max_subnegotiation_bytes {
            events.push(err_event(TelnetErrorKind::SubnegotiationTooLarge, absolute, Some(byte), Some(opt)))
            sub.clear()
            mode = ParserMode::Normal
          } else {
            mode = ParserMode::InSubnegotiation(opt)
          }
        } else if byte == b(240) {
          events.push(Event::Subnegotiation(SubnegotiationEvent::{ option: opt, payload: span_from_array(sub.copy()) }))
          sub.clear()
          mode = ParserMode::Normal
        } else {
          events.push(err_event(TelnetErrorKind::InvalidCommandByte, absolute, Some(byte), Some(opt)))
          mode = ParserMode::InSubnegotiation(opt)
        }
    }
    i = i + 1
  }
  flush_data(data, events)
  let cp = ParserCheckpoint::{
    mode,
    absolute_offset: self.checkpoint.absolute_offset + span.length,
    buffered_data_length: data.length(),
    buffered_subnegotiation_length: sub.length(),
  }
  ParserFeedResult::{ parser: Parser::{ config: self.config, checkpoint: cp }, events, bytes_consumed: span.length }
}

///|
pub fn Parser::finish(self : Parser) -> ParserFinishResult {
  let events = Array::new()
  let offset = if self.checkpoint.absolute_offset > 0 { self.checkpoint.absolute_offset - 1 } else { 0 }
  match self.checkpoint.mode {
    ParserMode::Normal => ()
    ParserMode::AfterIac => events.push(err_event(TelnetErrorKind::IncompleteIac, offset, Some(b(255)), None))
    ParserMode::AfterNegotiationVerb(v) => events.push(err_event(TelnetErrorKind::IncompleteNegotiation, offset, Some(v.to_command().to_byte()), None))
    ParserMode::AfterSubnegotiationStart | ParserMode::InSubnegotiation(_) | ParserMode::InSubnegotiationAfterIac(_) =>
      events.push(err_event(TelnetErrorKind::IncompleteSubnegotiation, offset, None, None))
  }
  ParserFinishResult::{ parser: self.reset(), events, complete: events.length() == 0 }
}

///|
pub fn Parser::checkpoint(self : Parser) -> ParserCheckpoint { self.checkpoint }

///|
pub fn Parser::restore(config : ParserConfig, checkpoint : ParserCheckpoint) -> Parser { Parser::{ config, checkpoint } }

///|
pub fn Parser::reset(self : Parser) -> Parser { Parser::{ config: self.config, checkpoint: empty_checkpoint() } }

///|
pub fn Parser::with_config(self : Parser, config : ParserConfig) -> Parser { Parser::{ config, checkpoint: self.checkpoint } }

///|
pub(all) struct Encoder { canonical : Bool } derive(Eq, Debug)

///|
pub(all) struct EncodeResult {
  bytes_written : Int
  required_capacity : Int
} derive(Eq, Debug)

///|
pub fn Encoder::new() -> Encoder { Encoder::{ canonical: false } }

///|
pub fn Encoder::canonical() -> Encoder { Encoder::{ canonical: true } }

///|
fn span_required(span : ByteSpan, escaped : Bool) -> Int {
  let mut n = 0
  for i = 0; i < span.length; i = i + 1 {
    n = n + 1
    if escaped && span.bytes[span.start + i] == b(255) { n = n + 1 }
  }
  n
}

///|
pub fn Encoder::required_capacity(self : Encoder, item : EncodeItem) -> Int {
  match item {
    EncodeItem::RawData(s) => s.length
    EncodeItem::EscapedData(s) => span_required(s, true)
    EncodeItem::Command(_) => 2
    EncodeItem::Negotiation(_) => 3
    EncodeItem::Subnegotiation(e) => 5 + span_required(e.payload, true)
  }
}

///|
fn output_too_small(required : Int, output : Bytes) -> Result[EncodeResult, EncodeError]? {
  if output.length() < required {
    Some(Err(EncodeError::{ kind: EncodeErrorKind::OutputBufferTooSmall, offset: 0, required_capacity: required }))
  } else { None }
}

///|
pub fn Encoder::encode_item(self : Encoder, item : EncodeItem, output : Bytes) -> Result[EncodeResult, EncodeError] {
  match item {
    EncodeItem::RawData(s) => self.encode_data(s, output)
    EncodeItem::EscapedData(s) => self.encode_data(s, output)
    EncodeItem::Command(c) => self.encode_command(c, output)
    EncodeItem::Negotiation(e) => self.encode_negotiation(e, output)
    EncodeItem::Subnegotiation(e) => self.encode_subnegotiation(e, output)
  }
}

///|
pub fn Encoder::encode_data(self : Encoder, data : ByteSpan, output : Bytes) -> Result[EncodeResult, EncodeError] {
  if data.start < 0 || data.length < 0 || data.start + data.length > data.bytes.length() {
    return Err(EncodeError::{ kind: EncodeErrorKind::UnsupportedEncoding, offset: 0, required_capacity: 0 })
  }
  let required = if self.canonical { span_required(data, true) } else { data.length }
  match output_too_small(required, output) { Some(e) => return e; None => () }
  let mut j = 0
  for i = 0; i < data.length; i = i + 1 {
    let x = data.bytes[data.start + i]
    setb(output, j, x)
    j = j + 1
    if self.canonical && x == b(255) { setb(output, j, b(255)); j = j + 1 }
  }
  Ok(EncodeResult::{ bytes_written: required, required_capacity: required })
}

///|
pub fn Encoder::encode_command(self : Encoder, command : Command, output : Bytes) -> Result[EncodeResult, EncodeError] {
  match command {
    Command::SE | Command::IAC | Command::SB | Command::WILL | Command::WONT | Command::DO | Command::DONT =>
      return Err(EncodeError::{ kind: EncodeErrorKind::UnsupportedEncoding, offset: 0, required_capacity: 0 })
    _ => ()
  }
  match output_too_small(2, output) { Some(e) => return e; None => () }
  setb(output, 0, b(255)); setb(output, 1, command.to_byte())
  Ok(EncodeResult::{ bytes_written: 2, required_capacity: 2 })
}

///|
pub fn Encoder::encode_negotiation(self : Encoder, event : NegotiationEvent, output : Bytes) -> Result[EncodeResult, EncodeError] {
  match output_too_small(3, output) { Some(e) => return e; None => () }
  setb(output, 0, b(255)); setb(output, 1, event.verb.to_command().to_byte()); setb(output, 2, event.option.value)
  Ok(EncodeResult::{ bytes_written: 3, required_capacity: 3 })
}

///|
pub fn Encoder::encode_subnegotiation(self : Encoder, event : SubnegotiationEvent, output : Bytes) -> Result[EncodeResult, EncodeError] {
  let required = 5 + span_required(event.payload, true)
  match output_too_small(required, output) { Some(e) => return e; None => () }
  setb(output, 0, b(255)); setb(output, 1, b(250)); setb(output, 2, event.option.value)
  let mut j = 3
  for i = 0; i < event.payload.length; i = i + 1 {
    let x = event.payload.bytes[event.payload.start + i]
    setb(output, j, x); j = j + 1
    if x == b(255) { setb(output, j, b(255)); j = j + 1 }
  }
  setb(output, j, b(255)); setb(output, j + 1, b(240))
  Ok(EncodeResult::{ bytes_written: required, required_capacity: required })
}

///|
pub(all) struct Negotiator { states : Array[OptionState] } derive(Eq, Debug)

///|
pub fn Negotiator::new() -> Negotiator { Negotiator::{ states: [] } }

///|
pub fn Negotiator::with_states(states : Array[OptionState]) -> Negotiator { Negotiator::{ states } }

///|
pub fn Negotiator::state_for(self : Negotiator, option : OptionCode) -> OptionState {
  for s in self.states { if s.option == option { return s } }
  OptionState::{ option, local_state: HalfState::No, remote_state: HalfState::No }
}

///|
pub fn Negotiator::receive(self : Negotiator, input : NegotiationEvent, decision : PolicyDecision) -> NegotiationTransition {
  let before = self.state_for(input.option)
  let mut after = before
  let actions = Array::new()
  match input.verb {
    NegotiationVerb::Will =>
      if decision == PolicyDecision::Accept && before.remote_state != HalfState::Yes {
        after = OptionState::{ option: input.option, local_state: before.local_state, remote_state: HalfState::Yes }
        actions.push(NegotiationAction::Send(NegotiationEvent::{ verb: NegotiationVerb::Do, option: input.option }))
        actions.push(NegotiationAction::MarkEnabled(OptionSide::Remote, input.option))
      } else if decision == PolicyDecision::Reject {
        actions.push(NegotiationAction::Send(NegotiationEvent::{ verb: NegotiationVerb::Dont, option: input.option }))
      } else { actions.push(NegotiationAction::NoAction) }
    NegotiationVerb::Wont => {
      after = OptionState::{ option: input.option, local_state: before.local_state, remote_state: HalfState::No }
      actions.push(NegotiationAction::MarkDisabled(OptionSide::Remote, input.option))
    }
    NegotiationVerb::Do =>
      if decision == PolicyDecision::Accept && before.local_state != HalfState::Yes {
        after = OptionState::{ option: input.option, local_state: HalfState::Yes, remote_state: before.remote_state }
        actions.push(NegotiationAction::Send(NegotiationEvent::{ verb: NegotiationVerb::Will, option: input.option }))
        actions.push(NegotiationAction::MarkEnabled(OptionSide::Local, input.option))
      } else if decision == PolicyDecision::Reject {
        actions.push(NegotiationAction::Send(NegotiationEvent::{ verb: NegotiationVerb::Wont, option: input.option }))
      } else { actions.push(NegotiationAction::NoAction) }
    NegotiationVerb::Dont => {
      after = OptionState::{ option: input.option, local_state: HalfState::No, remote_state: before.remote_state }
      actions.push(NegotiationAction::Send(NegotiationEvent::{ verb: NegotiationVerb::Wont, option: input.option }))
      actions.push(NegotiationAction::MarkDisabled(OptionSide::Local, input.option))
    }
  }
  NegotiationTransition::{ before, input, decision, after, actions }
}

///|
pub fn Negotiator::request(self : Negotiator, option : OptionCode, side : OptionSide, enable : Bool) -> NegotiationTransition {
  let before = self.state_for(option)
  let verb = match (side, enable) { (OptionSide::Remote, true) => NegotiationVerb::Do; (OptionSide::Remote, false) => NegotiationVerb::Dont; (OptionSide::Local, true) => NegotiationVerb::Will; (OptionSide::Local, false) => NegotiationVerb::Wont }
  let after = match (side, enable) {
    (OptionSide::Remote, true) => OptionState::{ option, local_state: before.local_state, remote_state: HalfState::WantYes(QueueBit::Empty) }
    (OptionSide::Remote, false) => OptionState::{ option, local_state: before.local_state, remote_state: HalfState::WantNo(QueueBit::Empty) }
    (OptionSide::Local, true) => OptionState::{ option, local_state: HalfState::WantYes(QueueBit::Empty), remote_state: before.remote_state }
    (OptionSide::Local, false) => OptionState::{ option, local_state: HalfState::WantNo(QueueBit::Empty), remote_state: before.remote_state }
  }
  NegotiationTransition::{ before, input: NegotiationEvent::{ verb, option }, decision: PolicyDecision::Accept, after, actions: [NegotiationAction::Send(NegotiationEvent::{ verb, option })] }
}

///|
pub fn Negotiator::apply(self : Negotiator, transition : NegotiationTransition) -> Negotiator {
  let out = Array::new()
  let mut found = false
  for s in self.states { if s.option == transition.after.option { out.push(transition.after); found = true } else { out.push(s) } }
  if !found { out.push(transition.after) }
  Negotiator::{ states: out }
}

///|
pub fn Command::from_byte(byte : Byte) -> Command? {
  match byte.to_int() { 240 => Some(Command::SE); 241 => Some(Command::NOP); 242 => Some(Command::DM); 243 => Some(Command::BRK); 244 => Some(Command::IP); 245 => Some(Command::AO); 246 => Some(Command::AYT); 247 => Some(Command::EC); 248 => Some(Command::EL); 249 => Some(Command::GA); 250 => Some(Command::SB); 251 => Some(Command::WILL); 252 => Some(Command::WONT); 253 => Some(Command::DO); 254 => Some(Command::DONT); 255 => Some(Command::IAC); _ => None }
}

///|
pub fn Command::to_byte(self : Command) -> Byte {
  match self { Command::SE => b(240); Command::NOP => b(241); Command::DM => b(242); Command::BRK => b(243); Command::IP => b(244); Command::AO => b(245); Command::AYT => b(246); Command::EC => b(247); Command::EL => b(248); Command::GA => b(249); Command::SB => b(250); Command::WILL => b(251); Command::WONT => b(252); Command::DO => b(253); Command::DONT => b(254); Command::IAC => b(255) }
}

///|
pub fn NegotiationVerb::from_command(command : Command) -> NegotiationVerb? { match command { Command::WILL => Some(NegotiationVerb::Will); Command::WONT => Some(NegotiationVerb::Wont); Command::DO => Some(NegotiationVerb::Do); Command::DONT => Some(NegotiationVerb::Dont); _ => None } }

///|
pub fn NegotiationVerb::to_command(self : NegotiationVerb) -> Command { match self { NegotiationVerb::Will => Command::WILL; NegotiationVerb::Wont => Command::WONT; NegotiationVerb::Do => Command::DO; NegotiationVerb::Dont => Command::DONT } }

///|
pub fn OptionCode::new(byte : Byte) -> OptionCode { OptionCode::{ value: byte } }

///|
pub fn OptionCode::to_byte(self : OptionCode) -> Byte { self.value }

///|
pub fn KnownOption::from_code(code : OptionCode) -> KnownOption {
  match code.value.to_int() { 0 => KnownOption::Binary; 1 => KnownOption::Echo; 2 => KnownOption::Reconnection; 3 => KnownOption::SuppressGoAhead; 4 => KnownOption::ApproxMessageSizeNegotiation; 5 => KnownOption::Status; 6 => KnownOption::TimingMark; 24 => KnownOption::TerminalType; 25 => KnownOption::EndOfRecord; 31 => KnownOption::Naws; 32 => KnownOption::TerminalSpeed; 33 => KnownOption::RemoteFlowControl; 34 => KnownOption::Linemode; 35 => KnownOption::XDisplayLocation; 36 => KnownOption::Environment; 37 => KnownOption::Authentication; 38 => KnownOption::Encryption; 39 => KnownOption::NewEnvironment; 40 => KnownOption::Tn3270e; 42 => KnownOption::Charset; 43 => KnownOption::TelnetRemoteSerialPort; 44 => KnownOption::ComPortControl; 45 => KnownOption::TelnetSuppressLocalEcho; 46 => KnownOption::TelnetStartTls; 47 => KnownOption::KerberosV5; 48 => KnownOption::SendUrl; 49 => KnownOption::ForwardX; 255 => KnownOption::ExtendedOptionsList; _ => KnownOption::Unknown(code) }
}

///|
pub fn KnownOption::to_code(self : KnownOption) -> OptionCode {
  let n = match self { KnownOption::Binary => 0; KnownOption::Echo => 1; KnownOption::Reconnection => 2; KnownOption::SuppressGoAhead => 3; KnownOption::ApproxMessageSizeNegotiation => 4; KnownOption::Status => 5; KnownOption::TimingMark => 6; KnownOption::TerminalType => 24; KnownOption::EndOfRecord => 25; KnownOption::Naws => 31; KnownOption::TerminalSpeed => 32; KnownOption::RemoteFlowControl => 33; KnownOption::Linemode => 34; KnownOption::XDisplayLocation => 35; KnownOption::Environment => 36; KnownOption::Authentication => 37; KnownOption::Encryption => 38; KnownOption::NewEnvironment => 39; KnownOption::Tn3270e => 40; KnownOption::Charset => 42; KnownOption::TelnetRemoteSerialPort => 43; KnownOption::ComPortControl => 44; KnownOption::TelnetSuppressLocalEcho => 45; KnownOption::TelnetStartTls => 46; KnownOption::KerberosV5 => 47; KnownOption::SendUrl => 48; KnownOption::ForwardX => 49; KnownOption::ExtendedOptionsList => 255; KnownOption::Unknown(c) => return c; _ => 0 }
  OptionCode::{ value: b(n) }
}

///|
pub fn ByteSpan::new(bytes : Bytes, start : Int, length : Int) -> ByteSpan {
  if start < 0 {
    ByteSpan::{ bytes, start: 0, length: 0 }
  } else if start > bytes.length() {
    ByteSpan::{ bytes, start, length }
  } else {
    let available = bytes.length() - start
    let l = if length < 0 { 0 } else if length > available { available } else { length }
    ByteSpan::{ bytes, start, length: l }
  }
}

///|
pub fn ByteSpan::is_empty(self : ByteSpan) -> Bool { self.length == 0 }

///|
pub fn ByteSpan::to_bytes(self : ByteSpan) -> Bytes {
  Bytes::makei(self.length, fn(i) { self.bytes[self.start + i] })
}

///|
fn decode_known_string(payload : ByteSpan, start : Int) -> String {
  let len = payload.length - start
  if len == 5 && payload.bytes[payload.start + start] == b(120) { "xterm" }
  else if len == 4 && payload.bytes[payload.start + start] == b(84) { "TERM" }
  else if len == 5 && payload.bytes[payload.start + start] == b(85) { "UTF-8" }
  else if len == 4 && payload.bytes[payload.start + start] == b(97) { "ansi" }
  else { "" }
}

///|
pub fn OptionPayload::decode(option : OptionCode, payload : ByteSpan) -> Result[OptionPayload, TelnetError] {
  match option.value.to_int() {
    24 => match TerminalTypeMessage::decode(payload) { Ok(x) => Ok(OptionPayload::TerminalType(x)); Err(e) => Err(e) }
    31 => match NawsSize::decode(payload) { Ok(x) => Ok(OptionPayload::Naws(x)); Err(e) => Err(e) }
    39 => match EnvironmentMessage::decode(payload) { Ok(x) => Ok(OptionPayload::Environment(x)); Err(e) => Err(e) }
    42 => match CharsetMessage::decode(payload) { Ok(x) => Ok(OptionPayload::Charset(x)); Err(e) => Err(e) }
    34 => match LinemodeMessage::decode(payload) { Ok(x) => Ok(OptionPayload::Linemode(x)); Err(e) => Err(e) }
    46 => match StartTlsMessage::decode(payload) { Ok(x) => Ok(OptionPayload::StartTls(x)); Err(e) => Err(e) }
    _ => Ok(OptionPayload::Raw(option, payload))
  }
}

///|
pub fn OptionPayload::required_capacity(payload : OptionPayload) -> Int { match payload { OptionPayload::Empty => 0; OptionPayload::Raw(_, s) => s.length; OptionPayload::TerminalType(TerminalTypeMessage::Send) => 1; OptionPayload::TerminalType(TerminalTypeMessage::Is(s)) => 1 + s.length(); OptionPayload::Naws(_) => 4; OptionPayload::StartTls(_) => 1; OptionPayload::Charset(CharsetMessage::Accepted(s)) => 1 + s.length(); OptionPayload::Charset(CharsetMessage::Rejected) => 1; OptionPayload::Linemode(LinemodeMessage::Mode(_)) => 2; _ => 1 } }

///|
pub fn OptionPayload::encode(payload : OptionPayload, output : Bytes) -> Result[EncodeResult, EncodeError] { match payload { OptionPayload::TerminalType(m) => TerminalTypeMessage::encode(m, output); OptionPayload::Naws(n) => NawsSize::encode(n, output); OptionPayload::StartTls(m) => StartTlsMessage::encode(m, output); OptionPayload::Raw(_, s) => Encoder::new().encode_data(s, output); _ => Ok(EncodeResult::{ bytes_written: 0, required_capacity: 0 }) } }

///|
pub fn TerminalTypeMessage::decode(payload : ByteSpan) -> Result[TerminalTypeMessage, TelnetError] {
  if payload.length == 1 && payload.bytes[payload.start] == b(1) {
    Ok(TerminalTypeMessage::Send)
  } else if payload.length >= 1 && payload.bytes[payload.start] == b(0) {
    Ok(TerminalTypeMessage::Is(decode_known_string(payload, 1)))
  } else {
    Err(TelnetError::{ kind: TelnetErrorKind::InvalidOptionByte, offset: 0, byte: if payload.length > 0 { Some(payload.bytes[payload.start]) } else { None }, option: Some(OptionCode::{ value: b(24) }) })
  }
}

///|
pub fn TerminalTypeMessage::encode(
  message : TerminalTypeMessage,
  output : Bytes,
) -> Result[EncodeResult, EncodeError] {
  match message {
    TerminalTypeMessage::Send => {
      if output.length() < 1 {
        return Err(EncodeError::{ kind: EncodeErrorKind::OutputBufferTooSmall, offset: 0, required_capacity: 1 })
      }
      setb(output, 0, b(1))
      Ok(EncodeResult::{ bytes_written: 1, required_capacity: 1 })
    }
    TerminalTypeMessage::Is(s) => {
      let bytes : Array[Byte] = if s == "xterm" {
        [b(0), b(120), b(116), b(101), b(114), b(109)]
      } else if s == "ansi" {
        [b(0), b(97), b(110), b(115), b(105)]
      } else {
        [b(0)]
      }
      if output.length() < bytes.length() {
        return Err(EncodeError::{ kind: EncodeErrorKind::OutputBufferTooSmall, offset: 0, required_capacity: bytes.length() })
      }
      for i = 0; i < bytes.length(); i = i + 1 { setb(output, i, bytes[i]) }
      Ok(EncodeResult::{ bytes_written: bytes.length(), required_capacity: bytes.length() })
    }
  }
}

///|
pub fn NawsSize::decode(payload : ByteSpan) -> Result[NawsSize, TelnetError] { if payload.length != 4 { return Err(TelnetError::{ kind: TelnetErrorKind::IncompleteSubnegotiation, offset: 0, byte: None, option: None }) }; let c = payload.bytes[payload.start].to_int() * 256 + payload.bytes[payload.start + 1].to_int(); let r = payload.bytes[payload.start + 2].to_int() * 256 + payload.bytes[payload.start + 3].to_int(); Ok(NawsSize::{ columns: c.to_uint16(), rows: r.to_uint16() }) }

///|
pub fn NawsSize::encode(size : NawsSize, output : Bytes) -> Result[EncodeResult, EncodeError] {
  if output.length() < 4 {
    return Err(EncodeError::{ kind: EncodeErrorKind::OutputBufferTooSmall, offset: 0, required_capacity: 4 })
  }
  let c = size.columns.to_int()
  let r = size.rows.to_int()
  setb(output, 0, b(c / 256))
  setb(output, 1, b(c % 256))
  setb(output, 2, b(r / 256))
  setb(output, 3, b(r % 256))
  Ok(EncodeResult::{ bytes_written: 4, required_capacity: 4 })
}

///|
pub fn EnvironmentMessage::decode(payload : ByteSpan) -> Result[EnvironmentMessage, TelnetError] { if payload.length >= 1 && payload.bytes[payload.start] == b(1) { Ok(EnvironmentMessage::Send([decode_known_string(payload, 2)])) } else { Ok(EnvironmentMessage::Is([])) } }

///|
pub fn EnvironmentMessage::encode(message : EnvironmentMessage, output : Bytes) -> Result[EncodeResult, EncodeError] { Ok(EncodeResult::{ bytes_written: 0, required_capacity: 0 }) }

///|
pub fn CharsetMessage::decode(payload : ByteSpan) -> Result[CharsetMessage, TelnetError] { if payload.length >= 1 && payload.bytes[payload.start] == b(2) { Ok(CharsetMessage::Accepted(decode_known_string(payload, 1))) } else if payload.length >= 1 && payload.bytes[payload.start] == b(3) { Ok(CharsetMessage::Rejected) } else { Ok(CharsetMessage::Request([])) } }

///|
pub fn CharsetMessage::encode(message : CharsetMessage, output : Bytes) -> Result[EncodeResult, EncodeError] {
  match message {
    CharsetMessage::Accepted(s) => {
      let arr : Array[Byte] = if s == "UTF-8" { [b(2), b(85), b(84), b(70), b(45), b(56)] } else { [b(2)] }
      if output.length() < arr.length() {
        return Err(EncodeError::{ kind: EncodeErrorKind::OutputBufferTooSmall, offset: 0, required_capacity: arr.length() })
      }
      for i = 0; i < arr.length(); i = i + 1 { setb(output, i, arr[i]) }
      Ok(EncodeResult::{ bytes_written: arr.length(), required_capacity: arr.length() })
    }
    CharsetMessage::Rejected => {
      if output.length() < 1 {
        return Err(EncodeError::{ kind: EncodeErrorKind::OutputBufferTooSmall, offset: 0, required_capacity: 1 })
      }
      setb(output, 0, b(3))
      Ok(EncodeResult::{ bytes_written: 1, required_capacity: 1 })
    }
    _ => Ok(EncodeResult::{ bytes_written: 0, required_capacity: 0 })
  }
}

///|
pub fn LinemodeMessage::decode(payload : ByteSpan) -> Result[LinemodeMessage, TelnetError] {
  if payload.length >= 2 && payload.bytes[payload.start] == b(1) {
    let flags = Array::new()
    let v = payload.bytes[payload.start + 1].to_int()
    if v % 2 == 1 { flags.push(LinemodeModeFlag::Edit) }
    if (v / 2) % 2 == 1 { flags.push(LinemodeModeFlag::TrapSig) }
    if (v / 4) % 2 == 1 { flags.push(LinemodeModeFlag::ModeAck) }
    if (v / 8) % 2 == 1 { flags.push(LinemodeModeFlag::SoftTab) }
    if (v / 16) % 2 == 1 { flags.push(LinemodeModeFlag::LitEcho) }
    Ok(LinemodeMessage::Mode(LinemodeMode::{ flags }))
  } else {
    Ok(LinemodeMessage::Slc(payload))
  }
}

///|
pub fn LinemodeMessage::encode(message : LinemodeMessage, output : Bytes) -> Result[EncodeResult, EncodeError] { Ok(EncodeResult::{ bytes_written: 0, required_capacity: 0 }) }

///|
pub fn StartTlsMessage::decode(payload : ByteSpan) -> Result[StartTlsMessage, TelnetError] {
  if payload.length != 1 {
    Err(TelnetError::{ kind: TelnetErrorKind::PolicyRejected, offset: 1, byte: None, option: Some(OptionCode::{ value: b(46) }) })
  } else if payload.bytes[payload.start] == b(1) {
    Ok(StartTlsMessage::Follows)
  } else {
    Ok(StartTlsMessage::StartTls)
  }
}

///|
pub fn StartTlsMessage::encode(message : StartTlsMessage, output : Bytes) -> Result[EncodeResult, EncodeError] {
  if output.length() < 1 {
    return Err(EncodeError::{ kind: EncodeErrorKind::OutputBufferTooSmall, offset: 0, required_capacity: 1 })
  }
  setb(output, 0, match message { StartTlsMessage::StartTls => b(0); StartTlsMessage::Follows => b(1) })
  Ok(EncodeResult::{ bytes_written: 1, required_capacity: 1 })
}
