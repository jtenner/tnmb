///| Benchmark runner for jtenner/telnet.

///|

///| Run with:

///|

///|   moon run --target js cmd/bench

///|   moon run --target native cmd/bench

///|   moon build --target wasm cmd/bench

///|   node tools/run-wasm-bench.mjs _build/wasm/debug/build/cmd/bench/bench.wasm

///|   moon build --target wasm-gc cmd/bench

///|   bun tools/run-wasm-bench.mjs _build/wasm-gc/debug/build/cmd/bench/bench.wasm

///|

///| The suite intentionally reports a simple checksum for every benchmark so

///| work cannot be trivially ignored and so runs are easier to sanity-check.

///|
#cfg(target="js")
extern "js" fn js_now_ms() -> Double =
  #| () => (typeof performance !== 'undefined' ? performance.now() : Date.now())

///|
#cfg(target="js")
fn now_us() -> Int64 {
  (js_now_ms() * 1000.0).to_int64()
}

///|
#cfg(target="native")
extern "C" fn now_us() -> Int64 = "moonbit_telnet_bench_now_us"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn now_us() -> Int64 = "moonbit:bench" "now_us"

///|
#cfg(not(any(target="js", target="native", target="wasm", target="wasm-gc")))
fn now_us() -> Int64 {
  abort(
    "cmd/bench timing is implemented for JS, native, wasm, and wasm-gc targets",
  )
}

///|
fn b(n : Int) -> Byte {
  n.to_byte()
}

///|
fn unsafe_bytes_to_fixedarray(bytes : Bytes) -> FixedArray[Byte] = "%identity"

///|
fn setb(bytes : Bytes, index : Int, value : Byte) -> Unit {
  unsafe_bytes_to_fixedarray(bytes)[index] = value
}

///|
fn span(bytes : Bytes) -> @telnet.ByteSpan {
  @telnet.ByteSpan::{ bytes, start: 0, length: bytes.length() }
}

///|
fn span_from_array(xs : Array[Byte]) -> @telnet.ByteSpan {
  span(Bytes::from_array(xs))
}

///|
fn opt(n : Int) -> @telnet.OptionCode {
  @telnet.OptionCode::new(b(n))
}

///|
fn neg(verb : @telnet.NegotiationVerb, n : Int) -> @telnet.NegotiationEvent {
  @telnet.NegotiationEvent::{ verb, option: opt(n) }
}

///|
fn option_state(
  n : Int,
  local_state : @telnet.HalfState,
  remote : @telnet.HalfState,
) -> @telnet.OptionState {
  @telnet.OptionState::{ option: opt(n), local_state, remote_state: remote }
}

///|
fn make_pattern(size : Int, kind : Int) -> Bytes {
  let bytes = Bytes::new(size)
  for i = 0; i < size; i = i + 1 {
    let x = match kind {
      0 => 65 + i % 26 // plain printable data
      1 => if i % 97 == 0 { 255 } else { 65 + i % 26 } // sparse IAC
      2 => if i % 4 == 0 { 255 } else { 65 + i % 26 } // dense IAC
      3 => 255 // all IAC
      4 => if i % 2 == 0 { 13 } else { 10 } // CRLF-ish
      _ => i % 251
    }
    setb(bytes, i, b(x))
  }
  bytes
}

///|
fn make_commands(count : Int) -> Bytes {
  let bytes = Bytes::new(count * 2)
  let cmds = [241, 242, 243, 244, 245, 246, 247, 248, 249]
  for i = 0; i < count; i = i + 1 {
    setb(bytes, i * 2, b(255))
    setb(bytes, i * 2 + 1, b(cmds[i % cmds.length()]))
  }
  bytes
}

///|
fn make_negotiations(count : Int) -> Bytes {
  let bytes = Bytes::new(count * 3)
  let verbs = [251, 252, 253, 254]
  for i = 0; i < count; i = i + 1 {
    setb(bytes, i * 3, b(255))
    setb(bytes, i * 3 + 1, b(verbs[i % verbs.length()]))
    setb(bytes, i * 3 + 2, b(i % 47))
  }
  bytes
}

///|
fn make_subnegotiation(payload_size : Int, iac_stride : Int) -> Bytes {
  let extra = if iac_stride <= 0 {
    0
  } else {
    (payload_size + iac_stride - 1) / iac_stride
  }
  let bytes = Bytes::new(5 + payload_size + extra)
  setb(bytes, 0, b(255))
  setb(bytes, 1, b(250))
  setb(bytes, 2, b(24))
  let mut j = 3
  for i = 0; i < payload_size; i = i + 1 {
    let x = if iac_stride > 0 && i % iac_stride == 0 {
      255
    } else {
      65 + i % 26
    }
    setb(bytes, j, b(x))
    j = j + 1
    if x == 255 {
      setb(bytes, j, b(255))
      j = j + 1
    }
  }
  setb(bytes, j, b(255))
  setb(bytes, j + 1, b(240))
  bytes
}

///|
fn make_malformed(count : Int) -> Bytes {
  let bytes = Bytes::new(count * 3)
  for i = 0; i < count; i = i + 1 {
    setb(bytes, i * 3, b(255))
    setb(bytes, i * 3 + 1, b(239)) // invalid TELNET command byte
    setb(bytes, i * 3 + 2, b(65 + i % 26))
  }
  bytes
}

///|
fn config(
  policy : @telnet.CrPolicy,
  coalescing : @telnet.DataCoalescing,
) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 8192,
    max_subnegotiation_bytes: 16384,
    cr_policy: policy,
    data_coalescing: coalescing,
    strict_commands: true,
  }
}

///|
fn parser_feed_once(
  input : Bytes,
  chunk_size : Int,
  cfg : @telnet.ParserConfig,
) -> Int {
  let mut parser = @telnet.Parser::new(cfg)
  let mut consumed = 0
  let mut events = 0
  let mut checksum = 0
  while consumed < input.length() {
    let n = if input.length() - consumed < chunk_size {
      input.length() - consumed
    } else {
      chunk_size
    }
    let result = parser.feed_span(@telnet.ByteSpan::{
      bytes: input,
      start: consumed,
      length: n,
    })
    parser = result.parser
    consumed = consumed + result.bytes_consumed
    events = events + result.events.length()
    checksum = checksum + events + parser.checkpoint().absolute_offset
  }
  let finish = parser.finish()
  checksum + finish.events.length() + (if finish.complete { 1 } else { 0 })
}

///|
fn parser_feed_once_into(
  input : Bytes,
  chunk_size : Int,
  cfg : @telnet.ParserConfig,
) -> Int {
  let mut parser = @telnet.Parser::new(cfg)
  let event_buffer = Array::new()
  let mut consumed = 0
  let mut events = 0
  let mut checksum = 0
  while consumed < input.length() {
    let n = if input.length() - consumed < chunk_size {
      input.length() - consumed
    } else {
      chunk_size
    }
    let result = parser.feed_span_into(
      @telnet.ByteSpan::{ bytes: input, start: consumed, length: n },
      event_buffer,
    )
    parser = result.parser
    consumed = consumed + result.bytes_consumed
    events = events + result.events.length()
    checksum = checksum + events + parser.checkpoint().absolute_offset
  }
  let finish = parser.finish()
  checksum + finish.events.length() + (if finish.complete { 1 } else { 0 })
}

///|
fn encode_data_once(input : Bytes, canonical : Bool) -> Int {
  let encoder = if canonical {
    @telnet.Encoder::canonical()
  } else {
    @telnet.Encoder::new()
  }
  let required = encoder.required_capacity(
    @telnet.EncodeItem::EscapedData(span(input)),
  )
  let output = Bytes::new(required)
  match encoder.encode_data(span(input), output) {
    Ok(r) => r.bytes_written + r.required_capacity + output[0].to_int()
    Err(e) => e.required_capacity
  }
}

///|
fn encode_data_assume_capacity_once(
  input : Bytes,
  required : Int,
  canonical : Bool,
) -> Int {
  let encoder = if canonical {
    @telnet.Encoder::canonical()
  } else {
    @telnet.Encoder::new()
  }
  let output = Bytes::new(required)
  match encoder.encode_data_assume_capacity(span(input), output, required) {
    Ok(r) => r.bytes_written + r.required_capacity + output[0].to_int()
    Err(e) => e.required_capacity
  }
}

///|
fn encode_subnegotiation_once(payload : Bytes) -> Int {
  let encoder = @telnet.Encoder::canonical()
  let event = @telnet.SubnegotiationEvent::{
    option: opt(24),
    payload: span(payload),
  }
  let required = encoder.required_capacity(
    @telnet.EncodeItem::Subnegotiation(event),
  )
  let output = Bytes::new(required)
  match encoder.encode_subnegotiation(event, output) {
    Ok(r) => r.bytes_written + output[required - 1].to_int()
    Err(e) => e.required_capacity
  }
}

///|
fn encode_subnegotiation_assume_capacity_once(
  payload : Bytes,
  required : Int,
) -> Int {
  let encoder = @telnet.Encoder::canonical()
  let event = @telnet.SubnegotiationEvent::{
    option: opt(24),
    payload: span(payload),
  }
  let output = Bytes::new(required)
  match encoder.encode_subnegotiation_assume_capacity(event, output, required) {
    Ok(r) => r.bytes_written + output[required - 1].to_int()
    Err(e) => e.required_capacity
  }
}

///|
fn encode_negotiation_loop(inner : Int) -> Int {
  let encoder = @telnet.Encoder::canonical()
  let output = Bytes::new(3)
  let verbs = [
    @telnet.NegotiationVerb::Will,
    @telnet.NegotiationVerb::Wont,
    @telnet.NegotiationVerb::Do,
    @telnet.NegotiationVerb::Dont,
  ]
  let mut sum = 0
  for i = 0; i < inner; i = i + 1 {
    match encoder.encode_negotiation(neg(verbs[i % 4], i % 47), output) {
      Ok(r) => sum = sum + r.bytes_written + output[1].to_int()
      Err(e) => sum = sum + e.required_capacity
    }
  }
  sum
}

///|
fn encode_command_loop(inner : Int) -> Int {
  let encoder = @telnet.Encoder::canonical()
  let output = Bytes::new(2)
  let cmds = [
    @telnet.Command::NOP,
    @telnet.Command::DM,
    @telnet.Command::BRK,
    @telnet.Command::IP,
    @telnet.Command::AO,
    @telnet.Command::AYT,
    @telnet.Command::EC,
    @telnet.Command::EL,
    @telnet.Command::GA,
  ]
  let mut sum = 0
  for i = 0; i < inner; i = i + 1 {
    match encoder.encode_command(cmds[i % cmds.length()], output) {
      Ok(r) => sum = sum + r.bytes_written + output[1].to_int()
      Err(e) => sum = sum + e.required_capacity
    }
  }
  sum
}

///|
fn decode_payload_once(payload : @telnet.ByteSpan, option : Int) -> Int {
  match @telnet.OptionPayload::decode(opt(option), payload) {
    Ok(p) => @telnet.OptionPayload::required_capacity(p)
    Err(e) =>
      e.offset +
      (match e.byte {
        Some(x) => x.to_int()
        None => 0
      })
  }
}

///|
fn encode_payload_once(payload : @telnet.OptionPayload) -> Int {
  let required = @telnet.OptionPayload::required_capacity(payload)
  let output = Bytes::new(required)
  match @telnet.OptionPayload::encode(payload, output) {
    Ok(r) => r.bytes_written + r.required_capacity
    Err(e) => e.required_capacity
  }
}

///|
fn negotiator_receive_loop(inner : Int) -> Int {
  let mut n = @telnet.Negotiator::new()
  let verbs = [
    @telnet.NegotiationVerb::Will,
    @telnet.NegotiationVerb::Wont,
    @telnet.NegotiationVerb::Do,
    @telnet.NegotiationVerb::Dont,
  ]
  let mut sum = 0
  for i = 0; i < inner; i = i + 1 {
    let t = n.receive(neg(verbs[i % 4], i % 64), @telnet.PolicyDecision::Accept)
    n = n.apply(t)
    sum = sum + n.state_for(opt(i % 64)).option.value.to_int()
  }
  sum
}

///|
fn negotiator_request_loop(inner : Int) -> Int {
  let mut n = @telnet.Negotiator::new()
  let mut sum = 0
  for i = 0; i < inner; i = i + 1 {
    let t = n.request(
      opt(i % 64),
      if i % 2 == 0 {
        @telnet.OptionSide::Remote
      } else {
        @telnet.OptionSide::Local
      },
      i % 3 != 0,
    )
    n = n.apply(t)
    sum = sum + t.actions.length() + t.after.option.value.to_int()
  }
  sum
}

///|
fn negotiator_apply_loop(state_count : Int, inner : Int) -> Int {
  let states = Array::new()
  for i = 0; i < state_count; i = i + 1 {
    states.push(option_state(i, @telnet.HalfState::No, @telnet.HalfState::No))
  }
  let mut n = @telnet.Negotiator::with_states(states)
  let mut sum = 0
  for i = 0; i < inner; i = i + 1 {
    let t = n.request(opt(i % state_count), @telnet.OptionSide::Remote, true)
    n = n.apply(t)
    sum = sum + n.state_for(opt(i % state_count)).option.value.to_int()
  }
  sum
}

///|
fn lookup_loop(inner : Int) -> Int {
  let mut sum = 0
  for i = 0; i < inner; i = i + 1 {
    match @telnet.Command::from_byte(b(240 + i % 16)) {
      Some(c) => sum = sum + c.to_byte().to_int()
      None => sum = sum + 1
    }
    let option = @telnet.KnownOption::from_code(opt(i % 256))
    sum = sum + option.to_code().value.to_int()
    match @telnet.NegotiationVerb::from_command(@telnet.Command::WILL) {
      Some(v) => sum = sum + v.to_command().to_byte().to_int()
      None => ()
    }
  }
  sum
}

///|
fn bytespan_loop(input : Bytes, inner : Int) -> Int {
  let mut sum = 0
  for i = 0; i < inner; i = i + 1 {
    let s = @telnet.ByteSpan::new(input, i % 8, input.length() - i % 8)
    let copy = s.to_bytes()
    sum = sum + copy.length() + (if s.is_empty() { 1 } else { 0 })
  }
  sum
}

///|
fn e2e_login_once() -> Int {
  let stream = Bytes::from_array([
    b(255),
    b(251),
    b(1),
    b(255),
    b(253),
    b(3),
    b(255),
    b(253),
    b(31),
    b(255),
    b(250),
    b(24),
    b(1),
    b(255),
    b(240),
    b(255),
    b(250),
    b(31),
    b(0),
    b(100),
    b(0),
    b(40),
    b(255),
    b(240),
    b(108),
    b(111),
    b(103),
    b(105),
    b(110),
    b(58),
    b(32),
  ])
  let parsed = @telnet.Parser::default().feed(stream)
  let mut n = @telnet.Negotiator::new()
  let mut sum = parsed.events.length()
  for event in parsed.events {
    match event {
      @telnet.Event::Negotiation(e) => {
        let t = n.receive(e, @telnet.PolicyDecision::Accept)
        n = n.apply(t)
        sum = sum + t.actions.length()
      }
      @telnet.Event::Subnegotiation(e) =>
        sum = sum + decode_payload_once(e.payload, e.option.value.to_int())
      _ => ()
    }
  }
  sum
}

///|
fn e2e_shell_once(input : Bytes) -> Int {
  parser_feed_once(
    input,
    16,
    config(
      @telnet.CrPolicy::Preserve,
      @telnet.DataCoalescing::CoalesceUntilCommand,
    ),
  )
}

///|
fn elapsed_us(start : Int64, stop : Int64) -> Int64 {
  let d = stop - start
  if d <= 0 {
    1
  } else {
    d
  }
}

///|
fn run_bench(
  name : String,
  iterations : Int,
  bytes_per_iter : Int,
  body : () -> Int,
) -> Unit {
  ignore(body()) // warmup
  let start = now_us()
  let mut checksum = 0
  for _i = 0; _i < iterations; _i = _i + 1 {
    checksum = checksum + body()
  }
  let stop = now_us()
  let us = elapsed_us(start, stop)
  let ms = us / 1000
  let total_bytes = iterations.to_int64() * bytes_per_iter.to_int64()
  let ops_per_sec = iterations.to_int64() * 1000000 / us
  let mb_per_sec = if bytes_per_iter == 0 { 0L } else { total_bytes / us }
  println(
    name +
    " | iters=" +
    iterations.to_string() +
    " | ms=" +
    ms.to_string() +
    " | ops/s=" +
    ops_per_sec.to_string() +
    " | MB/s=" +
    mb_per_sec.to_string() +
    " | checksum=" +
    checksum.to_string(),
  )
}

///|
fn main {
  let plain_1m = make_pattern(1024 * 1024, 0)
  let plain_64k = make_pattern(64 * 1024, 0)
  let sparse_iac = make_pattern(256 * 1024, 1)
  let dense_iac = make_pattern(256 * 1024, 2)
  let all_iac = make_pattern(64 * 1024, 3)
  let crlf = make_pattern(256 * 1024, 4)
  let commands = make_commands(65536)
  let negotiations = make_negotiations(65536)
  let sub_0 = make_subnegotiation(0, 0)
  let sub_16 = make_subnegotiation(16, 0)
  let sub_256 = make_subnegotiation(256, 17)
  let sub_4096 = make_subnegotiation(4096, 97)
  let sub_8192 = make_subnegotiation(8192, 97)
  let malformed = make_malformed(32768)
  let shell = make_subnegotiation(512, 89) +
    make_commands(16) +
    make_pattern(4096, 1)

  println("moonbit-telnet benchmark suite")
  println(
    "format: name | iters | elapsed ms | ops/s | approximate MB/s | checksum",
  )

  run_bench("parser_plain_1m_single_chunk", 40, plain_1m.length(), fn() {
    parser_feed_once(
      plain_1m,
      plain_1m.length(),
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_plain_1m_8192_chunks", 40, plain_1m.length(), fn() {
    parser_feed_once(
      plain_1m,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_plain_1m_8192_chunks_into", 40, plain_1m.length(), fn() {
    parser_feed_once_into(
      plain_1m,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_plain_1m_1460_chunks", 30, plain_1m.length(), fn() {
    parser_feed_once(
      plain_1m,
      1460,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_plain_64k_16_byte_chunks", 80, plain_64k.length(), fn() {
    parser_feed_once(
      plain_64k,
      16,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_plain_64k_byte_chunks", 8, plain_64k.length(), fn() {
    parser_feed_once(
      plain_64k,
      1,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_iac_escaped_sparse", 60, sparse_iac.length(), fn() {
    parser_feed_once(
      sparse_iac,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_iac_escaped_sparse_into", 60, sparse_iac.length(), fn() {
    parser_feed_once_into(
      sparse_iac,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_iac_escaped_dense", 60, dense_iac.length(), fn() {
    parser_feed_once(
      dense_iac,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_commands_heavy", 80, commands.length(), fn() {
    parser_feed_once(
      commands,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_negotiation_heavy", 80, negotiations.length(), fn() {
    parser_feed_once(
      negotiations,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_subnegotiation_0", 80000, sub_0.length(), fn() {
    parser_feed_once(
      sub_0,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_subnegotiation_16", 50000, sub_16.length(), fn() {
    parser_feed_once(
      sub_16,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_subnegotiation_256_escaped", 12000, sub_256.length(), fn() {
    parser_feed_once(
      sub_256,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_subnegotiation_4096_escaped", 1200, sub_4096.length(), fn() {
    parser_feed_once(
      sub_4096,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_subnegotiation_8192_escaped", 600, sub_8192.length(), fn() {
    parser_feed_once(
      sub_8192,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_malformed_error_heavy", 60, malformed.length(), fn() {
    parser_feed_once(
      malformed,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_cr_preserve", 60, crlf.length(), fn() {
    parser_feed_once(
      crlf,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_cr_validate_nvt", 60, crlf.length(), fn() {
    parser_feed_once(
      crlf,
      8192,
      config(
        @telnet.CrPolicy::ValidateNvt,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_cr_normalize_lf", 60, crlf.length(), fn() {
    parser_feed_once(
      crlf,
      8192,
      config(
        @telnet.CrPolicy::NormalizeToLf,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_coalescing_emit_immediately", 20, plain_64k.length(), fn() {
    parser_feed_once(
      plain_64k,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::EmitImmediately,
      ),
    )
  })
  run_bench("parser_coalescing_until_command", 80, plain_64k.length(), fn() {
    parser_feed_once(
      plain_64k,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
  run_bench("parser_coalescing_until_capacity", 80, plain_64k.length(), fn() {
    parser_feed_once(
      plain_64k,
      8192,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCapacity,
      ),
    )
  })

  let encoder = @telnet.Encoder::canonical()
  let sparse_iac_required = encoder.required_capacity(
    @telnet.EncodeItem::EscapedData(span(sparse_iac)),
  )
  let dense_iac_required = encoder.required_capacity(
    @telnet.EncodeItem::EscapedData(span(dense_iac)),
  )
  let all_iac_required = encoder.required_capacity(
    @telnet.EncodeItem::EscapedData(span(all_iac)),
  )
  let sub_8192_required = encoder.required_capacity(
    @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(24),
      payload: span(sub_8192),
    }),
  )
  run_bench("encoder_raw_1m", 60, plain_1m.length(), fn() {
    encode_data_once(plain_1m, false)
  })
  run_bench("encoder_raw_1m_assume_capacity", 60, plain_1m.length(), fn() {
    encode_data_assume_capacity_once(plain_1m, plain_1m.length(), false)
  })
  run_bench("encoder_canonical_no_iac", 60, plain_1m.length(), fn() {
    encode_data_once(plain_1m, true)
  })
  run_bench("encoder_canonical_no_iac_assume_capacity", 60, plain_1m.length(), fn() {
    encode_data_assume_capacity_once(plain_1m, plain_1m.length(), true)
  })
  run_bench("encoder_canonical_sparse_iac", 80, sparse_iac.length(), fn() {
    encode_data_once(sparse_iac, true)
  })
  run_bench(
    "encoder_canonical_sparse_iac_assume_capacity",
    80,
    sparse_iac.length(),
    fn() {
      encode_data_assume_capacity_once(sparse_iac, sparse_iac_required, true)
    },
  )
  run_bench("encoder_canonical_dense_iac", 80, dense_iac.length(), fn() {
    encode_data_once(dense_iac, true)
  })
  run_bench(
    "encoder_canonical_dense_iac_assume_capacity",
    80,
    dense_iac.length(),
    fn() {
      encode_data_assume_capacity_once(dense_iac, dense_iac_required, true)
    },
  )
  run_bench("encoder_canonical_all_iac", 80, all_iac.length(), fn() {
    encode_data_once(all_iac, true)
  })
  run_bench("encoder_canonical_all_iac_assume_capacity", 80, all_iac.length(), fn() {
    encode_data_assume_capacity_once(all_iac, all_iac_required, true)
  })
  run_bench("encoder_command", 50000, 0, fn() { encode_command_loop(64) })
  run_bench("encoder_negotiation", 50000, 0, fn() {
    encode_negotiation_loop(64)
  })
  run_bench("encoder_subnegotiation_8k", 4000, sub_8192.length(), fn() {
    encode_subnegotiation_once(sub_8192)
  })
  run_bench(
    "encoder_subnegotiation_8k_assume_capacity",
    4000,
    sub_8192.length(),
    fn() {
      encode_subnegotiation_assume_capacity_once(sub_8192, sub_8192_required)
    },
  )
  run_bench("encoder_required_capacity_escaped", 200, dense_iac.length(), fn() {
    @telnet.Encoder::canonical().required_capacity(
      @telnet.EncodeItem::EscapedData(span(dense_iac)),
    )
  })

  let terminal_type = span_from_array([
    b(0),
    b(120),
    b(116),
    b(101),
    b(114),
    b(109),
    b(45),
    b(50),
    b(53),
    b(54),
    b(99),
    b(111),
    b(108),
    b(111),
    b(114),
  ])
  let naws = span_from_array([b(0), b(100), b(0), b(40)])
  let env_small = span_from_array([
    b(0),
    b(0),
    b(85),
    b(83),
    b(69),
    b(82),
    b(1),
    b(109),
    b(111),
    b(111),
    b(110),
  ])
  let env_large = span_from_array([
    b(0),
    b(0),
    b(85),
    b(83),
    b(69),
    b(82),
    b(1),
    b(109),
    b(111),
    b(111),
    b(110),
    b(0),
    b(84),
    b(69),
    b(82),
    b(77),
    b(1),
    b(120),
    b(116),
    b(101),
    b(114),
    b(109),
    b(45),
    b(50),
    b(53),
    b(54),
    b(99),
    b(111),
    b(108),
    b(111),
    b(114),
    b(0),
    b(76),
    b(65),
    b(78),
    b(71),
    b(1),
    b(101),
    b(110),
    b(95),
    b(85),
    b(83),
    b(46),
    b(85),
    b(84),
    b(70),
    b(45),
    b(56),
  ])
  let charset_many = span_from_array([
    b(1),
    b(59),
    b(85),
    b(84),
    b(70),
    b(45),
    b(56),
    b(59),
    b(85),
    b(83),
    b(45),
    b(65),
    b(83),
    b(67),
    b(73),
    b(73),
    b(59),
    b(73),
    b(83),
    b(79),
    b(45),
    b(56),
    b(56),
    b(53),
    b(57),
    b(45),
    b(49),
  ])
  let linemode = span_from_array([b(2), b(1), b(2), b(3), b(4), b(5), b(6)])
  run_bench("payload_terminal_type_decode", 200000, terminal_type.length, fn() {
    decode_payload_once(terminal_type, 24)
  })
  run_bench("payload_naws_decode", 200000, naws.length, fn() {
    decode_payload_once(naws, 31)
  })
  run_bench("payload_environment_small_decode", 150000, env_small.length, fn() {
    decode_payload_once(env_small, 39)
  })
  run_bench("payload_environment_large_decode", 80000, env_large.length, fn() {
    decode_payload_once(env_large, 39)
  })
  run_bench("payload_charset_many_decode", 120000, charset_many.length, fn() {
    decode_payload_once(charset_many, 42)
  })
  run_bench("payload_linemode_forward_mask_decode", 200000, linemode.length, fn() {
    decode_payload_once(linemode, 34)
  })
  run_bench("payload_raw_unknown_decode", 200000, sub_256.length(), fn() {
    decode_payload_once(span(sub_256), 37)
  })
  run_bench("payload_terminal_type_encode", 200000, terminal_type.length, fn() {
    encode_payload_once(
      @telnet.OptionPayload::TerminalType(
        @telnet.TerminalTypeMessage::Is("xterm-256color"),
      ),
    )
  })
  run_bench("payload_naws_encode", 200000, 4, fn() {
    encode_payload_once(
      @telnet.OptionPayload::Naws(@telnet.NawsSize::{
        columns: (100).to_uint16(),
        rows: (40).to_uint16(),
      }),
    )
  })
  run_bench("payload_environment_encode", 120000, env_small.length, fn() {
    encode_payload_once(
      @telnet.OptionPayload::Environment(
        @telnet.EnvironmentMessage::Is([
          @telnet.EnvironmentVariable::{
            kind: @telnet.EnvironmentVariableKind::Var,
            name: "USER",
            value: Some("moon"),
          },
        ]),
      ),
    )
  })
  run_bench("payload_charset_encode", 120000, charset_many.length, fn() {
    encode_payload_once(
      @telnet.OptionPayload::Charset(
        @telnet.CharsetMessage::Request(["UTF-8", "US-ASCII", "ISO-8859-1"]),
      ),
    )
  })
  run_bench("payload_linemode_encode", 200000, linemode.length, fn() {
    encode_payload_once(
      @telnet.OptionPayload::Linemode(
        @telnet.LinemodeMessage::ForwardMask(
          @telnet.LinemodeForwardMask::Bytes(
            span_from_array([b(1), b(2), b(3), b(4), b(5), b(6)]),
          ),
        ),
      ),
    )
  })

  run_bench("negotiator_receive_accept", 50000, 0, fn() {
    negotiator_receive_loop(64)
  })
  run_bench("negotiator_request_enable_disable", 50000, 0, fn() {
    negotiator_request_loop(64)
  })
  run_bench("negotiator_apply_1_state", 100000, 0, fn() {
    negotiator_apply_loop(1, 16)
  })
  run_bench("negotiator_apply_8_states", 80000, 0, fn() {
    negotiator_apply_loop(8, 16)
  })
  run_bench("negotiator_apply_32_states", 50000, 0, fn() {
    negotiator_apply_loop(32, 16)
  })
  run_bench("negotiator_apply_64_states", 30000, 0, fn() {
    negotiator_apply_loop(64, 16)
  })
  run_bench("negotiator_apply_256_states", 8000, 0, fn() {
    negotiator_apply_loop(256, 16)
  })

  run_bench("lookup_mapping_helpers", 200000, 0, fn() { lookup_loop(64) })
  run_bench("bytespan_to_bytes", 1000, plain_64k.length() * 16, fn() {
    bytespan_loop(plain_64k, 16)
  })

  run_bench("e2e_login_negotiation", 100000, 31, fn() { e2e_login_once() })
  run_bench("e2e_interactive_shell", 20000, shell.length(), fn() {
    e2e_shell_once(shell)
  })
  run_bench("e2e_large_terminal_output", 60, sparse_iac.length(), fn() {
    parser_feed_once(
      sparse_iac,
      1460,
      config(
        @telnet.CrPolicy::Preserve,
        @telnet.DataCoalescing::CoalesceUntilCommand,
      ),
    )
  })
}
