// Deterministic performance/complexity guardrails. These avoid wall-clock timing
// and instead assert bounded event counts, byte accounting, and completion state.

///|
fn guardrail_count_kind(events : Array[@telnet.Event], want : String) -> Int {
  let mut n = 0
  events.each(fn(event) {
    match (event, want) {
      (@telnet.Event::Data(_), "data") => n = n + 1
      (@telnet.Event::Command(_), "command") => n = n + 1
      (@telnet.Event::Negotiation(_), "negotiation") => n = n + 1
      (@telnet.Event::Subnegotiation(_), "subnegotiation") => n = n + 1
      (@telnet.Event::Error(_), "error") => n = n + 1
      _ => ()
    }
  })
  n
}

///|
test "complexity guard large no-IAC data emits capacity-bounded events" {
  let wire = Bytes::from_array(Array::make(65535, byte(65)))
  let r = @telnet.Parser::default().feed(wire)
  assert_true(r.bytes_consumed == 65535)
  assert_true(r.events.length() == 8)
  assert_true(guardrail_count_kind(r.events, "data") == 8)
  assert_true(r.parser.checkpoint.absolute_offset == 65535)
  assert_true(r.parser.finish().events == [])
}

///|
test "complexity guard dense escaped IAC emits one event per escaped byte" {
  let wire = Array::new()
  for i = 0; i < 1024; i = i + 1 {
    ignore(i)
    wire.push(255)
    wire.push(255)
  }
  let r = @telnet.Parser::default().feed(bytes(wire))
  assert_true(r.bytes_consumed == 2048)
  assert_true(r.events.length() == 1024)
  assert_true(guardrail_count_kind(r.events, "data") == 1024)
  assert_true(r.parser.finish().events == [])
}

///|
test "complexity guard negotiation storm event count equals triplets" {
  let wire = Array::new()
  for i = 0; i < 400; i = i + 1 {
    wire.push(255)
    wire.push(251 + i % 4)
    wire.push(i % 50)
  }
  let r = @telnet.Parser::default().feed(bytes(wire))
  assert_true(r.bytes_consumed == 1200)
  assert_true(r.events.length() == 400)
  assert_true(guardrail_count_kind(r.events, "negotiation") == 400)
  assert_true(r.parser.finish().events == [])
}

///|
test "complexity guard oversized subnegotiation discards once and resumes" {
  let config = @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 32,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
  let payload = Array::make(80, 65)
  let wire = [255, 250, 50] + payload + [255, 240, 66]
  let r = @telnet.Parser::new(config).feed(bytes(wire))
  assert_true(r.bytes_consumed == wire.length())
  assert_true(r.events.length() == 2)
  assert_true(guardrail_count_kind(r.events, "error") == 1)
  assert_true(guardrail_count_kind(r.events, "data") == 1)
  match r.events[0] {
    @telnet.Event::Error(e) => {
      assert_true(e.kind == @telnet.TelnetErrorKind::SubnegotiationTooLarge)
      assert_true(e.option == None)
    }
    _ => assert_true(false)
  }
  assert_true(r.events[1] == data([66]))
}

///|
test "complexity guard command storm has stable byte accounting" {
  let wire = Array::new()
  for i = 0; i < 256; i = i + 1 {
    ignore(i)
    wire.push(255)
    wire.push(241)
  }
  let r = @telnet.Parser::default().feed(bytes(wire))
  assert_true(r.bytes_consumed == 512)
  assert_true(r.events.length() == 256)
  assert_true(guardrail_count_kind(r.events, "command") == 256)
  assert_true(r.events[0] == cmd(@telnet.Command::NOP))
  assert_true(r.events[255] == cmd(@telnet.Command::NOP))
}
