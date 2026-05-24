///| Long-running deterministic fuzz runner for moonbit-telnet/telnet.

///|

///| Default fast smoke run:

///|

///|   moon run cmd/fuzz

///|

///| CI-friendly deterministic run:

///|

///|   moon run cmd/fuzz -- ci

///|

///| Configurable extended run:

///|

///|   moon run cmd/fuzz -- <seed> <iterations> <max-length> <target>

///|

///| Targets: all, smoke, streaming, stability.

///|
enum FuzzTarget {
  All
  Smoke
  Streaming
  Stability
} derive(Eq, Debug)

///|
struct FuzzSettings {
  seed : Int
  iterations : Int
  max_length : Int
  target : FuzzTarget
} derive(Eq, Debug)

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
fn fuzz_rng(seed : Int) -> @fuzz_common.FuzzRng {
  @fuzz_common.rng(seed)
}

///|
fn fuzz_telnet_biased_bytes(seed : Int, length : Int) -> Bytes {
  @fuzz_common.telnet_biased_bytes(seed, length)
}

///|
fn fuzz_input_for_iteration(settings : FuzzSettings, iteration : Int) -> Bytes {
  let input_seed = settings.seed + iteration * 7919
  let (_, length) = fuzz_rng(input_seed).bounded_int(settings.max_length + 1)
  fuzz_telnet_biased_bytes(input_seed + 17, length)
}

///|
fn fuzz_parser_config(index : Int) -> @telnet.ParserConfig {
  @fuzz_common.parser_config(index)
}

///|
fn fuzz_roundtrip_parser_config() -> @telnet.ParserConfig {
  @fuzz_common.roundtrip_parser_config()
}

///|
fn fuzz_bytes_literal(data : Bytes) -> String {
  @fuzz_common.bytes_literal(data)
}

///|
fn fuzz_reproduction_line(
  target : String,
  settings : FuzzSettings,
  iteration : Int,
  input : Bytes,
) -> String {
  "target=" +
  target +
  " seed=" +
  settings.seed.to_string() +
  " iteration=" +
  iteration.to_string() +
  " max_length=" +
  settings.max_length.to_string() +
  " wire=bytes(" +
  fuzz_bytes_literal(input) +
  ")"
}

///|
fn fuzz_int_array_summary(items : Array[Int]) -> String {
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
fn fuzz_observation_summary(observation : FuzzParseObservation) -> String {
  "complete=" +
  (if observation.complete { "true" } else { "false" }) +
  " events=" +
  observation.events.length().to_string()
}

///|
fn fuzz_concat_bytes(left : Bytes, right : Bytes) -> Bytes {
  @fuzz_common.concat_bytes(left, right)
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
  @fuzz_common.bytes_slice(input, start, length)
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
fn fuzz_observe_chunks(
  config : @telnet.ParserConfig,
  input : Bytes,
  chunks : Array[Int],
  target : String,
  settings : FuzzSettings,
  iteration : Int,
) -> FuzzParseObservation {
  let mut parser = @telnet.Parser::new(config)
  let mut offset = 0
  let mut events : Array[@telnet.Event] = []
  chunks.each(fn(size) {
    if size < 0 || offset + size > input.length() {
      println(fuzz_reproduction_line(target, settings, iteration, input))
      println(
        "bad chunk size=" + size.to_string() + " offset=" + offset.to_string(),
      )
      abort("fuzz runner produced invalid chunk")
    }
    let before = parser.checkpoint()
    let fed = parser.feed(fuzz_bytes_slice(input, offset, size))
    if fed.bytes_consumed != size {
      println(fuzz_reproduction_line(target, settings, iteration, input))
      println(
        "chunk size=" +
        size.to_string() +
        " consumed=" +
        fed.bytes_consumed.to_string(),
      )
      abort("parser did not consume a full fuzz chunk")
    }
    if size == 0 &&
      (fed.events.length() != 0 || fed.parser.checkpoint() != before) {
      println(fuzz_reproduction_line(target, settings, iteration, input))
      println("empty feed changed parser state")
      abort("parser empty-feed instability")
    }
    events = events + fed.events
    parser = fed.parser
    offset = offset + size
  })
  if offset != input.length() {
    println(fuzz_reproduction_line(target, settings, iteration, input))
    println("final offset=" + offset.to_string())
    abort("fuzz chunks did not cover input")
  }
  let finished = parser.finish()
  FuzzParseObservation::{
    events: fuzz_normalize_events(events + finished.events),
    complete: finished.complete,
  }
}

///|
fn fuzz_span_from_bytes(data : Bytes) -> @telnet.ByteSpan {
  @fuzz_common.span_from_bytes(data)
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
  target : String,
  settings : FuzzSettings,
  iteration : Int,
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
          println(fuzz_reproduction_line(target, settings, iteration, input))
          println("required=" + required.to_string())
          abort("encoder capacity mismatch in fuzz runner")
        }
      Err(error) => {
        println(fuzz_reproduction_line(target, settings, iteration, input))
        println(
          "required=" +
          required.to_string() +
          " error_required=" +
          error.required_capacity.to_string(),
        )
        abort("encoder rejected parser-observed event in fuzz runner")
      }
    }
    wire_parts.push_iter(output.to_array().iter())
  })
  Bytes::from_array(wire_parts)
}

///|
fn fuzz_assert_parser_smoke(
  config : @telnet.ParserConfig,
  input : Bytes,
  settings : FuzzSettings,
  iteration : Int,
) -> Int {
  let fed = @telnet.Parser::new(config).feed(input)
  if fed.bytes_consumed != input.length() {
    println(fuzz_reproduction_line("smoke", settings, iteration, input))
    println("consumed=" + fed.bytes_consumed.to_string())
    abort("parser smoke did not consume input")
  }
  let checkpoint = fed.parser.checkpoint()
  if checkpoint.absolute_offset != input.length() ||
    checkpoint.buffered_data_length < 0 ||
    checkpoint.buffered_subnegotiation_length < 0 {
    println(fuzz_reproduction_line("smoke", settings, iteration, input))
    abort("parser smoke produced invalid checkpoint")
  }
  if fed.events.length() > input.length() + 1 {
    println(fuzz_reproduction_line("smoke", settings, iteration, input))
    println("events=" + fed.events.length().to_string())
    abort("parser smoke produced too many events")
  }
  let finished = fed.parser.finish()
  if finished.events.length() > 1 ||
    finished.parser.checkpoint().absolute_offset != 0 {
    println(fuzz_reproduction_line("smoke", settings, iteration, input))
    abort("parser smoke finish invariant failed")
  }
  fed.events.length() + finished.events.length() + checkpoint.absolute_offset
}

///|
fn fuzz_assert_streaming(
  input : Bytes,
  settings : FuzzSettings,
  iteration : Int,
) -> Int {
  let config = fuzz_roundtrip_parser_config()
  let expected = fuzz_observe_whole(config, input)
  let chunks = fuzz_random_chunks(
    settings.seed + iteration * 3571 + 31,
    input.length(),
  )
  let observed = fuzz_observe_chunks(
    config, input, chunks, "streaming", settings, iteration,
  )
  if observed != expected {
    println(fuzz_reproduction_line("streaming", settings, iteration, input))
    println("chunks=" + fuzz_int_array_summary(chunks))
    println("expected=" + fuzz_observation_summary(expected))
    println("observed=" + fuzz_observation_summary(observed))
    abort("parser streaming equivalence mismatch")
  }
  observed.events.length() + (if observed.complete { 1 } else { 0 })
}

///|
fn fuzz_assert_stability(
  input : Bytes,
  settings : FuzzSettings,
  iteration : Int,
) -> Int {
  let config = fuzz_roundtrip_parser_config()
  let first = fuzz_observe_whole(config, input)
  match fuzz_observation_to_encode_items(first) {
    None =>
      if first.complete && !fuzz_observation_has_error(first) {
        println(fuzz_reproduction_line("stability", settings, iteration, input))
        println("observed=" + fuzz_observation_summary(first))
        abort("parse/encode stability found unencodable non-error case")
      } else {
        first.events.length()
      }
    Some(items) => {
      let wire = fuzz_encode_items_to_wire(
        items, "stability", settings, iteration, input,
      )
      let second = fuzz_observe_whole(config, wire)
      if !second.complete || second.events != first.events {
        println(fuzz_reproduction_line("stability", settings, iteration, input))
        println("canonical_wire=bytes(" + fuzz_bytes_literal(wire) + ")")
        println("expected=" + fuzz_observation_summary(first))
        println("observed=" + fuzz_observation_summary(second))
        abort("parse/encode stability mismatch")
      }
      second.events.length() + wire.length()
    }
  }
}

///|
fn fuzz_target_name(target : FuzzTarget) -> String {
  match target {
    FuzzTarget::All => "all"
    FuzzTarget::Smoke => "smoke"
    FuzzTarget::Streaming => "streaming"
    FuzzTarget::Stability => "stability"
  }
}

///|
fn fuzz_parse_target(value : String) -> FuzzTarget {
  match value {
    "smoke" => FuzzTarget::Smoke
    "streaming" => FuzzTarget::Streaming
    "stability" => FuzzTarget::Stability
    "all" => FuzzTarget::All
    _ => {
      println("unknown fuzz target '" + value + "', using all")
      FuzzTarget::All
    }
  }
}

///|
fn fuzz_parse_int_arg(args : Array[String], index : Int, default : Int) -> Int {
  if index >= args.length() {
    default
  } else {
    @string.parse_int(args[index][:]) catch {
      _ => default
    }
  }
}

///|
fn fuzz_arg_or(args : Array[String], index : Int, default : String) -> String {
  if index >= args.length() {
    default
  } else {
    args[index]
  }
}

///|
fn fuzz_user_args(args : Array[String]) -> Array[String] {
  let out : Array[String] = []
  for i = 1; i < args.length(); i = i + 1 {
    out.push(args[i])
  }
  out
}

///|
fn fuzz_ci_settings() -> FuzzSettings {
  FuzzSettings::{
    seed: 20260524,
    iterations: 4096,
    max_length: 192,
    target: FuzzTarget::All,
  }
}

///|
fn fuzz_settings_from_args(args : Array[String]) -> FuzzSettings {
  let user_args = fuzz_user_args(args)
  if user_args.length() > 0 && user_args[0] == "ci" {
    fuzz_ci_settings()
  } else {
    let seed = fuzz_parse_int_arg(user_args, 0, 424242)
    let iterations = fuzz_parse_int_arg(user_args, 1, 1024)
    let max_length = fuzz_parse_int_arg(user_args, 2, 128)
    let target = fuzz_parse_target(fuzz_arg_or(user_args, 3, "all"))
    FuzzSettings::{
      seed,
      iterations: if iterations < 0 {
        0
      } else {
        iterations
      },
      max_length: if max_length < 0 {
        0
      } else {
        max_length
      },
      target,
    }
  }
}

///|
fn fuzz_run(settings : FuzzSettings) -> Int {
  let mut checksum = 0
  for iteration = 0; iteration < settings.iterations; iteration = iteration + 1 {
    let input = fuzz_input_for_iteration(settings, iteration)
    match settings.target {
      FuzzTarget::All => {
        for config_index = 0; config_index < 5; config_index = config_index + 1 {
          checksum = checksum +
            fuzz_assert_parser_smoke(
              fuzz_parser_config(config_index),
              input,
              settings,
              iteration,
            )
        }
        checksum = checksum + fuzz_assert_streaming(input, settings, iteration)
        checksum = checksum + fuzz_assert_stability(input, settings, iteration)
      }
      FuzzTarget::Smoke =>
        for config_index = 0; config_index < 5; config_index = config_index + 1 {
          checksum = checksum +
            fuzz_assert_parser_smoke(
              fuzz_parser_config(config_index),
              input,
              settings,
              iteration,
            )
        }
      FuzzTarget::Streaming =>
        checksum = checksum + fuzz_assert_streaming(input, settings, iteration)
      FuzzTarget::Stability =>
        checksum = checksum + fuzz_assert_stability(input, settings, iteration)
    }
  }
  checksum
}

///|
fn main {
  let settings = fuzz_settings_from_args(@env.args())
  println(
    "telnet fuzz seed=" +
    settings.seed.to_string() +
    " iterations=" +
    settings.iterations.to_string() +
    " max_length=" +
    settings.max_length.to_string() +
    " target=" +
    fuzz_target_name(settings.target),
  )
  let checksum = fuzz_run(settings)
  println("telnet fuzz ok checksum=" + checksum.to_string())
}
