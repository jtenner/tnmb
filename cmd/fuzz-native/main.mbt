///| Native stdin harness for optional coverage-guided TELNET fuzzing.

///|

///| The default `moon test` suite does not run this package. Build/run it

///| explicitly with `moon run --target native cmd/fuzz-native` or compile the

///| generated C with an external instrumenting compiler.

///|
struct NativeFuzzSettings {
  max_input_bytes : Int
} derive(Eq, Debug)

///|
enum NativeObservedEvent {
  Data(Bytes)
  Command(@telnet.Command)
  Negotiation(@telnet.NegotiationEvent)
  Subnegotiation(@telnet.OptionCode, Bytes)
  Error(@telnet.TelnetError)
} derive(Eq, Debug)

///|
struct NativeParseObservation {
  events : Array[NativeObservedEvent]
  complete : Bool
} derive(Eq, Debug)

///|
#cfg(target="native")
extern "C" fn native_read_stdin(max_bytes : Int) -> Bytes = "moonbit_telnet_fuzz_read_stdin"

///|
#cfg(not(target="native"))
fn native_read_stdin(_max_bytes : Int) -> Bytes {
  abort("cmd/fuzz-native must be run with --target native")
}

///|
fn native_settings_from_args(args : Array[String]) -> NativeFuzzSettings {
  let max_input_bytes = if args.length() > 1 {
    @string.parse_int(args[1][:]) catch {
      _ => 4096
    }
  } else {
    4096
  }
  NativeFuzzSettings::{
    max_input_bytes: if max_input_bytes < 0 {
      0
    } else {
      max_input_bytes
    },
  }
}

///|
fn native_parser_config(index : Int) -> @telnet.ParserConfig {
  @fuzz_common.parser_config(index)
}

///|
fn native_roundtrip_parser_config() -> @telnet.ParserConfig {
  @fuzz_common.roundtrip_parser_config()
}

///|
fn native_bytes_literal(data : Bytes) -> String {
  @fuzz_common.bytes_literal(data)
}

///|
fn native_reproduction_line(target : String, input : Bytes) -> String {
  "target=" +
  target +
  " length=" +
  input.length().to_string() +
  " wire=bytes(" +
  native_bytes_literal(input) +
  ")"
}

///|
fn native_concat_bytes(left : Bytes, right : Bytes) -> Bytes {
  @fuzz_common.concat_bytes(left, right)
}

///|
fn native_push_data_event(
  out : Array[NativeObservedEvent],
  data : Bytes,
) -> Unit {
  if data.length() == 0 {
    return
  }
  if out.length() == 0 {
    out.push(NativeObservedEvent::Data(data))
    return
  }
  let last_index = out.length() - 1
  match out[last_index] {
    NativeObservedEvent::Data(existing) =>
      out[last_index] = NativeObservedEvent::Data(
        native_concat_bytes(existing, data),
      )
    _ => out.push(NativeObservedEvent::Data(data))
  }
}

///|
fn native_push_normalized_event(
  out : Array[NativeObservedEvent],
  event : @telnet.Event,
) -> Unit {
  match event {
    @telnet.Event::Data(e) => native_push_data_event(out, e.span.to_bytes())
    @telnet.Event::Command(e) =>
      out.push(NativeObservedEvent::Command(e.command))
    @telnet.Event::Negotiation(e) =>
      out.push(NativeObservedEvent::Negotiation(e))
    @telnet.Event::Subnegotiation(e) =>
      out.push(
        NativeObservedEvent::Subnegotiation(e.option, e.payload.to_bytes()),
      )
    @telnet.Event::Error(e) => out.push(NativeObservedEvent::Error(e))
  }
}

///|
fn native_normalize_events(
  events : Array[@telnet.Event],
) -> Array[NativeObservedEvent] {
  let out : Array[NativeObservedEvent] = []
  events.each(fn(event) { native_push_normalized_event(out, event) })
  out
}

///|
fn native_bytes_slice(input : Bytes, start : Int, length : Int) -> Bytes {
  @fuzz_common.bytes_slice(input, start, length)
}

///|
fn native_observe_whole(
  config : @telnet.ParserConfig,
  input : Bytes,
) -> NativeParseObservation {
  let fed = @telnet.Parser::new(config).feed(input)
  let finished = fed.parser.finish()
  NativeParseObservation::{
    events: native_normalize_events(fed.events + finished.events),
    complete: finished.complete,
  }
}

///|
fn native_one_byte_chunks(length : Int) -> Array[Int] {
  @fuzz_common.one_byte_chunks(length)
}

///|
fn native_observe_chunks(
  config : @telnet.ParserConfig,
  input : Bytes,
  chunks : Array[Int],
  target : String,
) -> NativeParseObservation {
  let mut parser = @telnet.Parser::new(config)
  let mut offset = 0
  let mut events : Array[@telnet.Event] = []
  chunks.each(fn(size) {
    if size < 0 || offset + size > input.length() {
      println(native_reproduction_line(target, input))
      println(
        "bad chunk size=" + size.to_string() + " offset=" + offset.to_string(),
      )
      abort("native fuzzer produced invalid chunk")
    }
    let before = parser.checkpoint()
    let fed = parser.feed(native_bytes_slice(input, offset, size))
    if fed.bytes_consumed != size {
      println(native_reproduction_line(target, input))
      println(
        "chunk size=" +
        size.to_string() +
        " consumed=" +
        fed.bytes_consumed.to_string(),
      )
      abort("parser did not consume a full native fuzz chunk")
    }
    if size == 0 &&
      (fed.events.length() != 0 || fed.parser.checkpoint() != before) {
      println(native_reproduction_line(target, input))
      println("empty feed changed parser state")
      abort("parser empty-feed instability")
    }
    events = events + fed.events
    parser = fed.parser
    offset = offset + size
  })
  if offset != input.length() {
    println(native_reproduction_line(target, input))
    println("final offset=" + offset.to_string())
    abort("native fuzz chunks did not cover input")
  }
  let finished = parser.finish()
  NativeParseObservation::{
    events: native_normalize_events(events + finished.events),
    complete: finished.complete,
  }
}

///|
fn native_span_from_bytes(data : Bytes) -> @telnet.ByteSpan {
  @fuzz_common.span_from_bytes(data)
}

///|
fn native_observation_has_error(observation : NativeParseObservation) -> Bool {
  let mut found = false
  observation.events.each(fn(event) {
    match event {
      NativeObservedEvent::Error(_) => found = true
      _ => ()
    }
  })
  found
}

///|
fn native_observation_to_encode_items(
  observation : NativeParseObservation,
) -> Array[@telnet.EncodeItem]? {
  if !observation.complete {
    return None
  }
  let items : Array[@telnet.EncodeItem] = []
  let mut encodable = true
  observation.events.each(fn(event) {
    match event {
      NativeObservedEvent::Data(data) =>
        items.push(
          @telnet.EncodeItem::EscapedData(native_span_from_bytes(data)),
        )
      NativeObservedEvent::Command(command) =>
        items.push(@telnet.EncodeItem::Command(command))
      NativeObservedEvent::Negotiation(event) =>
        items.push(@telnet.EncodeItem::Negotiation(event))
      NativeObservedEvent::Subnegotiation(option, payload) =>
        items.push(
          @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
            option,
            payload: native_span_from_bytes(payload),
          }),
        )
      NativeObservedEvent::Error(_) => encodable = false
    }
  })
  if encodable {
    Some(items)
  } else {
    None
  }
}

///|
fn native_encode_items_to_wire(
  items : Array[@telnet.EncodeItem],
  input : Bytes,
) -> Bytes {
  let encoder = @telnet.Encoder::canonical()
  let wire_parts : Array[Byte] = []
  items.each(fn(item) {
    let required = encoder.required_capacity(item)
    let output = Bytes::new(required)
    match encoder.encode_item(item, output) {
      Ok(result) =>
        if result.bytes_written != required ||
          result.required_capacity != required {
          println(native_reproduction_line("stability", input))
          println("required=" + required.to_string())
          abort("encoder capacity mismatch in native fuzz harness")
        }
      Err(error) => {
        println(native_reproduction_line("stability", input))
        println(
          "required=" +
          required.to_string() +
          " error_required=" +
          error.required_capacity.to_string(),
        )
        abort("encoder rejected parser-observed event in native fuzz harness")
      }
    }
    wire_parts.push_iter(output.to_array().iter())
  })
  Bytes::from_array(wire_parts)
}

///|
fn native_observation_summary(observation : NativeParseObservation) -> String {
  "complete=" +
  (if observation.complete { "true" } else { "false" }) +
  " events=" +
  observation.events.length().to_string()
}

///|
fn native_assert_parser_smoke(
  config : @telnet.ParserConfig,
  input : Bytes,
) -> Int {
  let fed = @telnet.Parser::new(config).feed(input)
  if fed.bytes_consumed != input.length() {
    println(native_reproduction_line("smoke", input))
    println("consumed=" + fed.bytes_consumed.to_string())
    abort("parser smoke did not consume input")
  }
  let checkpoint = fed.parser.checkpoint()
  if checkpoint.absolute_offset != input.length() ||
    checkpoint.buffered_data_length < 0 ||
    checkpoint.buffered_subnegotiation_length < 0 {
    println(native_reproduction_line("smoke", input))
    abort("parser smoke produced invalid checkpoint")
  }
  if fed.events.length() > input.length() + 1 {
    println(native_reproduction_line("smoke", input))
    println("events=" + fed.events.length().to_string())
    abort("parser smoke produced too many events")
  }
  let finished = fed.parser.finish()
  if finished.events.length() > 1 ||
    finished.parser.checkpoint().absolute_offset != 0 {
    println(native_reproduction_line("smoke", input))
    abort("parser smoke finish invariant failed")
  }
  fed.events.length() + finished.events.length() + checkpoint.absolute_offset
}

///|
fn native_assert_streaming(input : Bytes) -> Int {
  let config = native_roundtrip_parser_config()
  let expected = native_observe_whole(config, input)
  let observed = native_observe_chunks(
    config,
    input,
    native_one_byte_chunks(input.length()),
    "streaming",
  )
  if observed != expected {
    println(native_reproduction_line("streaming", input))
    println("expected=" + native_observation_summary(expected))
    println("observed=" + native_observation_summary(observed))
    abort("parser streaming equivalence mismatch")
  }
  observed.events.length() + (if observed.complete { 1 } else { 0 })
}

///|
fn native_assert_stability(input : Bytes) -> Int {
  let config = native_roundtrip_parser_config()
  let first = native_observe_whole(config, input)
  match native_observation_to_encode_items(first) {
    None =>
      if first.complete && !native_observation_has_error(first) {
        println(native_reproduction_line("stability", input))
        println("observed=" + native_observation_summary(first))
        abort("parse/encode stability found unencodable non-error case")
      } else {
        first.events.length()
      }
    Some(items) => {
      let wire = native_encode_items_to_wire(items, input)
      let second = native_observe_whole(config, wire)
      if !second.complete || second.events != first.events {
        println(native_reproduction_line("stability", input))
        println("canonical_wire=bytes(" + native_bytes_literal(wire) + ")")
        println("expected=" + native_observation_summary(first))
        println("observed=" + native_observation_summary(second))
        abort("parse/encode stability mismatch")
      }
      second.events.length() + wire.length()
    }
  }
}

///|
fn native_run(input : Bytes) -> Int {
  let mut checksum = 0
  for config_index = 0; config_index < 5; config_index = config_index + 1 {
    checksum = checksum +
      native_assert_parser_smoke(native_parser_config(config_index), input)
  }
  checksum = checksum + native_assert_streaming(input)
  checksum = checksum + native_assert_stability(input)
  checksum
}

///|
fn main {
  let settings = native_settings_from_args(@env.args())
  let input = native_read_stdin(settings.max_input_bytes)
  let checksum = native_run(input)
  println(
    "telnet native fuzz ok length=" +
    input.length().to_string() +
    " max_input_bytes=" +
    settings.max_input_bytes.to_string() +
    " checksum=" +
    checksum.to_string(),
  )
}
