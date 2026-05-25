// RFC1143/Q-method transition-table characterization. These tests deliberately
// assert the current public negotiator behavior without changing production
// code. Normative gaps are recorded in docs/wiki/test-plan-negotiator-session.md.

///|
fn rfc1143_first_send(
  actions : Array[@telnet.NegotiationAction],
) -> @telnet.NegotiationEvent? {
  for action in actions {
    match action {
      @telnet.NegotiationAction::Send(e) => return Some(e)
      _ => ()
    }
  }
  None
}

///|
fn rfc1143_has_enabled(
  actions : Array[@telnet.NegotiationAction],
  side : @telnet.OptionSide,
  option : Int,
) -> Bool {
  for action in actions {
    match action {
      @telnet.NegotiationAction::MarkEnabled(s, o) =>
        if s == side && o == opt(option) {
          return true
        }
      _ => ()
    }
  }
  false
}

///|
fn rfc1143_has_disabled(
  actions : Array[@telnet.NegotiationAction],
  side : @telnet.OptionSide,
  option : Int,
) -> Bool {
  for action in actions {
    match action {
      @telnet.NegotiationAction::MarkDisabled(s, o) =>
        if s == side && o == opt(option) {
          return true
        }
      _ => ()
    }
  }
  false
}

///|
test "RFC1143 characterization receive does not mutate negotiator until apply" {
  let n = @telnet.Negotiator::new()
  let t = n.receive(
    neg_event(@telnet.NegotiationVerb::Will, 31),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(n.state_for(opt(31)).remote_state == @telnet.HalfState::No)
  assert_true(t.after.remote_state == @telnet.HalfState::Yes)
  let applied = n.apply(t)
  assert_true(applied.state_for(opt(31)).remote_state == @telnet.HalfState::Yes)
  assert_true(n.state_for(opt(31)).remote_state == @telnet.HalfState::No)
}

///|
test "RFC1143 characterization apply updates only the matching option" {
  let n = @telnet.Negotiator::with_states([
    option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
    option_state(31, @telnet.HalfState::No, @telnet.HalfState::No),
  ])
  let t = n.request(opt(31), @telnet.OptionSide::Remote, true)
  let applied = n.apply(t)
  assert_true(
    applied.state_for(opt(1)) ==
    option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
  )
  assert_true(
    applied.state_for(opt(31)).remote_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
  )
}

///|
test "RFC1143 characterization pending remote WILL accept currently sends DO" {
  let n = @telnet.Negotiator::with_states([
    option_state(
      24,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
  ])
  let t = n.receive(
    neg_event(@telnet.NegotiationVerb::Will, 24),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    t.after == option_state(24, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )
  assert_true(
    rfc1143_first_send(t.actions) ==
    Some(neg_event(@telnet.NegotiationVerb::Do, 24)),
  )
  assert_true(rfc1143_has_enabled(t.actions, @telnet.OptionSide::Remote, 24))
}

///|
test "RFC1143 characterization pending local DO accept currently sends WILL" {
  let n = @telnet.Negotiator::with_states([
    option_state(
      1,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
  ])
  let t = n.receive(
    neg_event(@telnet.NegotiationVerb::Do, 1),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    t.after == option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
  )
  assert_true(
    rfc1143_first_send(t.actions) ==
    Some(neg_event(@telnet.NegotiationVerb::Will, 1)),
  )
  assert_true(rfc1143_has_enabled(t.actions, @telnet.OptionSide::Local, 1))
}

///|
test "RFC1143 characterization pending refusals collapse to disabled state" {
  let remote_pending = @telnet.Negotiator::with_states([
    option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
  ])
  let wont = remote_pending.receive(
    neg_event(@telnet.NegotiationVerb::Wont, 31),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    wont.after == option_state(31, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(
    rfc1143_has_disabled(wont.actions, @telnet.OptionSide::Remote, 31),
  )

  let local_pending = @telnet.Negotiator::with_states([
    option_state(
      1,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
  ])
  let dont = local_pending.receive(
    neg_event(@telnet.NegotiationVerb::Dont, 1),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    dont.after == option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(
    rfc1143_first_send(dont.actions) ==
    Some(neg_event(@telnet.NegotiationVerb::Wont, 1)),
  )
  assert_true(rfc1143_has_disabled(dont.actions, @telnet.OptionSide::Local, 1))
}

///|
test "RFC1143 characterization queued opposite requests are represented on WantYes" {
  let local_pending = @telnet.Negotiator::with_states([
    option_state(
      1,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
  ])
  let local_disable = local_pending.request(
    opt(1),
    @telnet.OptionSide::Local,
    false,
  )
  assert_true(
    local_disable.after.local_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
  )
  assert_true(rfc1143_first_send(local_disable.actions) == None)

  let remote_pending = @telnet.Negotiator::with_states([
    option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
  ])
  let remote_disable = remote_pending.request(
    opt(31),
    @telnet.OptionSide::Remote,
    false,
  )
  assert_true(
    remote_disable.after.remote_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
  )
  assert_true(rfc1143_first_send(remote_disable.actions) == None)
}

///|
test "RFC1143 characterization duplicate disabled DONT currently replies WONT" {
  let n = @telnet.Negotiator::new()
  let t = n.receive(
    neg_event(@telnet.NegotiationVerb::Dont, 3),
    @telnet.PolicyDecision::Ignore,
  )
  assert_true(
    t.after == option_state(3, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(
    rfc1143_first_send(t.actions) ==
    Some(neg_event(@telnet.NegotiationVerb::Wont, 3)),
  )
}

///|
test "RFC1143 characterization duplicate disabled WONT stays disabled without reply" {
  let n = @telnet.Negotiator::new()
  let t = n.receive(
    neg_event(@telnet.NegotiationVerb::Wont, 24),
    @telnet.PolicyDecision::Ignore,
  )
  assert_true(
    t.after == option_state(24, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(rfc1143_first_send(t.actions) == None)
  assert_true(rfc1143_has_disabled(t.actions, @telnet.OptionSide::Remote, 24))
}

///|
test "RFC1143 characterization WantNo opposite receive drops queued enable" {
  let local_negotiator = @telnet.Negotiator::with_states([
    option_state(
      1,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
  ])
  let local_done = local_negotiator.receive(
    neg_event(@telnet.NegotiationVerb::Dont, 1),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    local_done.after ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(
    rfc1143_first_send(local_done.actions) ==
    Some(neg_event(@telnet.NegotiationVerb::Wont, 1)),
  )
  assert_true(
    rfc1143_has_disabled(local_done.actions, @telnet.OptionSide::Local, 1),
  )

  let remote = @telnet.Negotiator::with_states([
    option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
  ])
  let remote_done = remote.receive(
    neg_event(@telnet.NegotiationVerb::Wont, 31),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    remote_done.after ==
    option_state(31, @telnet.HalfState::No, @telnet.HalfState::No),
  )
  assert_true(rfc1143_first_send(remote_done.actions) == None)
  assert_true(
    rfc1143_has_disabled(remote_done.actions, @telnet.OptionSide::Remote, 31),
  )
}

///|
test "RFC1143 characterization WantYes opposite receive enables without queued disable" {
  let local_negotiator = @telnet.Negotiator::with_states([
    option_state(
      3,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
  ])
  let local_done = local_negotiator.receive(
    neg_event(@telnet.NegotiationVerb::Do, 3),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    local_done.after ==
    option_state(3, @telnet.HalfState::Yes, @telnet.HalfState::No),
  )
  assert_true(
    rfc1143_first_send(local_done.actions) ==
    Some(neg_event(@telnet.NegotiationVerb::Will, 3)),
  )
  assert_true(
    rfc1143_has_enabled(local_done.actions, @telnet.OptionSide::Local, 3),
  )

  let remote = @telnet.Negotiator::with_states([
    option_state(
      24,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
  ])
  let remote_done = remote.receive(
    neg_event(@telnet.NegotiationVerb::Will, 24),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    remote_done.after ==
    option_state(24, @telnet.HalfState::No, @telnet.HalfState::Yes),
  )
  assert_true(
    rfc1143_first_send(remote_done.actions) ==
    Some(neg_event(@telnet.NegotiationVerb::Do, 24)),
  )
  assert_true(
    rfc1143_has_enabled(remote_done.actions, @telnet.OptionSide::Remote, 24),
  )
}
