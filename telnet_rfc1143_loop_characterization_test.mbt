// RFC1143/Q-method loop-prevention characterization tests. These focus on
// observable safety properties: duplicate/refusal inputs must not emit opposite
// negotiation storms.

///|
fn rfc1143_send_count(actions : Array[@telnet.NegotiationAction]) -> Int {
  let mut n = 0
  actions.each(fn(action) {
    match action {
      @telnet.NegotiationAction::Send(_) => n = n + 1
      _ => ()
    }
  })
  n
}

///|
test "RFC1143 characterization duplicate WILL on enabled remote sends no reply" {
  let n = @telnet.Negotiator::with_states([
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
  ])
  let accept = n.receive(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    accept.after ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )
  assert_true(rfc1143_send_count(accept.actions) == 0)
  let ignore = n.receive(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Ignore,
  )
  assert_true(
    ignore.after ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )
  assert_true(rfc1143_send_count(ignore.actions) == 0)
}

///|
test "RFC1143 characterization duplicate DO on enabled local sends no reply" {
  let n = @telnet.Negotiator::with_states([
    option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
  ])
  let accept = n.receive(
    neg_event(@telnet.NegotiationVerb::Do, 1),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    accept.after ==
    option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
  )
  assert_true(rfc1143_send_count(accept.actions) == 0)
  let ignore = n.receive(
    neg_event(@telnet.NegotiationVerb::Do, 1),
    @telnet.PolicyDecision::Ignore,
  )
  assert_true(
    ignore.after ==
    option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
  )
  assert_true(rfc1143_send_count(ignore.actions) == 0)
}

///|
test "RFC1143 characterization refusals do not trigger reply storms" {
  let disabled = @telnet.Negotiator::new()
  let wont = disabled.receive(
    neg_event(@telnet.NegotiationVerb::Wont, 1),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    wont.after == option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(rfc1143_send_count(wont.actions) == 0)
  let dont = disabled.receive(
    neg_event(@telnet.NegotiationVerb::Dont, 1),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    dont.after == option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(rfc1143_send_count(dont.actions) <= 1)
}

///|
test "RFC1143 characterization repeated request while pending queues or no-ops without extra sends" {
  let base = @telnet.Negotiator::with_states([
    option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
  ])
  let disable = base.request(opt(31), @telnet.OptionSide::Remote, false)
  assert_true(
    disable.after ==
    option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
  )
  assert_true(rfc1143_send_count(disable.actions) == 0)
  let enable_again = base.request(opt(31), @telnet.OptionSide::Remote, true)
  assert_true(rfc1143_send_count(enable_again.actions) <= 1)
}
