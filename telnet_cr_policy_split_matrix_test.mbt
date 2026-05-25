// CR policy split-boundary matrix. These tests characterize how each CR
// policy behaves when TELNET framing bytes arrive across every chunk boundary.

///|
fn cr_split_config(policy : @telnet.CrPolicy) -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: policy,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
fn cr_split_span_bytes(span : @telnet.ByteSpan) -> Array[Int] {
  let out : Array[Int] = []
  for i = 0; i < span.length; i = i + 1 {
    out.push(span.bytes[span.start + i].to_int())
  }
  out
}

///|
fn cr_split_normalize_adjacent_data(
  events : Array[@telnet.Event],
) -> Array[@telnet.Event] {
  let out : Array[@telnet.Event] = []
  let mut pending : Array[Int] = []
  fn flush_pending() {
    if pending.length() > 0 {
      out.push(data(pending))
      pending = []
    }
  }
  events.each(fn(event) {
    match event {
      @telnet.Event::Data(d) => pending = pending + cr_split_span_bytes(d.span)
      other => {
        flush_pending()
        out.push(other)
      }
    }
  })
  flush_pending()
  out
}

///|
fn cr_split_events_equal(
  actual : Array[@telnet.Event],
  expected : Array[@telnet.Event],
) -> Bool {
  events_semantically_equal(
    cr_split_normalize_adjacent_data(actual),
    cr_split_normalize_adjacent_data(expected),
  )
}

///|
fn cr_split_events_all_splits(
  policy : @telnet.CrPolicy,
  wire : Array[Int],
  expected : Array[@telnet.Event],
) -> Unit raise {
  let config = cr_split_config(policy)
  for split = 0; split <= wire.length(); split = split + 1 {
    let first = @telnet.Parser::new(config).feed(
      tdd_bytes_slice(wire, 0, split),
    )
    let second = first.parser.feed(
      tdd_bytes_slice(wire, split, wire.length() - split),
    )
    let finished = second.parser.finish()
    assert_true(first.bytes_consumed == split)
    assert_true(second.bytes_consumed == wire.length() - split)
    let actual = first.events + second.events + finished.events
    assert_true(cr_split_events_equal(actual, expected))
  }
}

///|
fn cr_split_expect_data_cases(
  policy : @telnet.CrPolicy,
  crnul : Array[@telnet.Event],
  crlf : Array[@telnet.Event],
  crx : Array[@telnet.Event],
  bare_finish : Array[@telnet.Event],
) -> Unit raise {
  cr_split_events_all_splits(policy, [13, 0], crnul)
  cr_split_events_all_splits(policy, [13, 10], crlf)
  cr_split_events_all_splits(policy, [13, 88], crx)
  cr_split_events_all_splits(policy, [13], bare_finish)
}

///|
test "CR policy split matrix covers data CR pairs and finish" {
  cr_split_expect_data_cases(
    @telnet.CrPolicy::Preserve,
    [data([13, 0])],
    [data([13, 10])],
    [data([13, 88])],
    [data([13])],
  )
  cr_split_expect_data_cases(
    @telnet.CrPolicy::ValidateNvt,
    [data([13, 0])],
    [data([13, 10])],
    [err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(88)), data([88])],
    [err(@telnet.TelnetErrorKind::PolicyRejected, 0, Some(13))],
  )
  cr_split_expect_data_cases(
    @telnet.CrPolicy::NormalizeToLf,
    [data([13])],
    [data([10])],
    [data([13, 88])],
    [err(@telnet.TelnetErrorKind::PolicyRejected, 0, Some(13))],
  )
}

///|
fn cr_split_expect_telnet_boundary_cases(
  policy : @telnet.CrPolicy,
  command_expected : Array[@telnet.Event],
  escaped_iac_expected : Array[@telnet.Event],
  negotiation_expected : Array[@telnet.Event],
) -> Unit raise {
  cr_split_events_all_splits(policy, [13, 255, 241], command_expected)
  cr_split_events_all_splits(policy, [13, 255, 255], escaped_iac_expected)
  cr_split_events_all_splits(policy, [13, 255, 251, 1], negotiation_expected)
}

///|
test "CR policy split matrix covers IAC command escaped data and negotiation" {
  let preserved_or_normalized_command = [data([13]), cmd(@telnet.Command::NOP)]
  let preserved_or_normalized_escaped = [data([13]), data([255])]
  let preserved_or_normalized_negotiation = [
    data([13]),
    neg(@telnet.NegotiationVerb::Will, 1),
  ]
  cr_split_expect_telnet_boundary_cases(
    @telnet.CrPolicy::Preserve,
    preserved_or_normalized_command,
    preserved_or_normalized_escaped,
    preserved_or_normalized_negotiation,
  )
  cr_split_expect_telnet_boundary_cases(
    @telnet.CrPolicy::NormalizeToLf,
    preserved_or_normalized_command,
    preserved_or_normalized_escaped,
    preserved_or_normalized_negotiation,
  )
  cr_split_expect_telnet_boundary_cases(
    @telnet.CrPolicy::ValidateNvt,
    [
      err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(255)),
      cmd(@telnet.Command::NOP),
    ],
    [err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(255)), data([255])],
    [
      err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(255)),
      neg(@telnet.NegotiationVerb::Will, 1),
    ],
  )
}

///|
fn cr_split_expect_subnegotiation_cases(
  policy : @telnet.CrPolicy,
  before_sb_expected : Array[@telnet.Event],
) -> Unit raise {
  cr_split_events_all_splits(
    policy,
    [13, 255, 250, 24, 65, 255, 240, 66],
    before_sb_expected,
  )
  cr_split_events_all_splits(policy, [255, 250, 24, 65, 13, 88, 255, 240], [
    sb(24, [65, 13, 88]),
  ])
  cr_split_events_all_splits(policy, [255, 250, 24, 13, 255, 255, 255, 240], [
    sb(24, [13, 255]),
  ])
}

///|
test "CR policy split matrix leaves subnegotiation payload bytes untouched" {
  let preserve_or_normalize = [data([13]), sb(24, [65]), data([66])]
  cr_split_expect_subnegotiation_cases(
    @telnet.CrPolicy::Preserve,
    preserve_or_normalize,
  )
  cr_split_expect_subnegotiation_cases(
    @telnet.CrPolicy::NormalizeToLf,
    preserve_or_normalize,
  )
  cr_split_expect_subnegotiation_cases(@telnet.CrPolicy::ValidateNvt, [
    err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(255)),
    sb(24, [65]),
    data([66]),
  ])
}
