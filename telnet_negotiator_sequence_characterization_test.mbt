// Stateful negotiator sequence characterization. These tests assert current
// public Negotiator behavior step by step without changing production code.

///|
fn seq_send_count(actions : Array[@telnet.NegotiationAction]) -> Int {
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
fn seq_assert_bounded(transition : @telnet.NegotiationTransition) -> Unit raise {
  assert_true(seq_send_count(transition.actions) <= 1)
}

///|
fn seq_apply(
  negotiator : @telnet.Negotiator,
  transition : @telnet.NegotiationTransition,
) -> @telnet.Negotiator raise {
  seq_assert_bounded(transition)
  assert_true(
    negotiator.state_for(transition.after.option) == transition.before,
  )
  let applied = negotiator.apply(transition)
  assert_true(applied.state_for(transition.after.option) == transition.after)
  applied
}

///|
test "negotiator sequence remote enable request accepts or refuses deterministically" {
  let requested = @telnet.Negotiator::new().request(
    opt(31),
    @telnet.OptionSide::Remote,
    true,
  )
  assert_true(
    requested.actions ==
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Do, 31),
      ),
    ],
  )
  let pending = seq_apply(@telnet.Negotiator::new(), requested)
  assert_true(
    pending.state_for(opt(31)).remote_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
  )

  let accepted = pending.receive(
    neg_event(@telnet.NegotiationVerb::Will, 31),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    accepted.actions ==
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Do, 31),
      ),
      @telnet.NegotiationAction::MarkEnabled(
        @telnet.OptionSide::Remote,
        opt(31),
      ),
    ],
  )
  let enabled = seq_apply(pending, accepted)
  assert_true(enabled.state_for(opt(31)).remote_state == @telnet.HalfState::Yes)
  assert_true(pending.state_for(opt(31)).remote_state != @telnet.HalfState::Yes)

  let refused = pending.receive(
    neg_event(@telnet.NegotiationVerb::Wont, 31),
    @telnet.PolicyDecision::Accept,
  )
  let disabled = seq_apply(pending, refused)
  assert_true(disabled.state_for(opt(31)).remote_state == @telnet.HalfState::No)
}

///|
test "negotiator sequence local enable request accepts or refuses deterministically" {
  let requested = @telnet.Negotiator::new().request(
    opt(1),
    @telnet.OptionSide::Local,
    true,
  )
  assert_true(
    requested.actions ==
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 1),
      ),
    ],
  )
  let pending = seq_apply(@telnet.Negotiator::new(), requested)
  assert_true(
    pending.state_for(opt(1)).local_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
  )

  let accepted = pending.receive(
    neg_event(@telnet.NegotiationVerb::Do, 1),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(
    accepted.actions ==
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 1),
      ),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Local, opt(1)),
    ],
  )
  let enabled = seq_apply(pending, accepted)
  assert_true(enabled.state_for(opt(1)).local_state == @telnet.HalfState::Yes)
  assert_true(pending.state_for(opt(1)).local_state != @telnet.HalfState::Yes)

  let refused = pending.receive(
    neg_event(@telnet.NegotiationVerb::Dont, 1),
    @telnet.PolicyDecision::Accept,
  )
  let disabled = seq_apply(pending, refused)
  assert_true(disabled.state_for(opt(1)).local_state == @telnet.HalfState::No)
}

///|
test "negotiator sequence disable while enable is pending queues opposite request" {
  let remote_pending = seq_apply(
    @telnet.Negotiator::new(),
    @telnet.Negotiator::new().request(opt(24), @telnet.OptionSide::Remote, true),
  )
  let remote_disable = remote_pending.request(
    opt(24),
    @telnet.OptionSide::Remote,
    false,
  )
  assert_true(remote_disable.actions == [@telnet.NegotiationAction::NoAction])
  assert_true(
    remote_disable.after.remote_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
  )
  let remote_queued = seq_apply(remote_pending, remote_disable)
  assert_true(
    remote_queued.state_for(opt(24)).remote_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
  )

  let local_pending = seq_apply(
    @telnet.Negotiator::new(),
    @telnet.Negotiator::new().request(opt(3), @telnet.OptionSide::Local, true),
  )
  let local_disable = local_pending.request(
    opt(3),
    @telnet.OptionSide::Local,
    false,
  )
  assert_true(local_disable.actions == [@telnet.NegotiationAction::NoAction])
  assert_true(
    local_disable.after.local_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
  )
  let local_queued = seq_apply(local_pending, local_disable)
  assert_true(
    local_queued.state_for(opt(3)).local_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
  )
}

///|
test "negotiator sequence queued disable after pending enable currently settles enabled" {
  let n0 = @telnet.Negotiator::new()
  let remote_requested = seq_apply(
    n0,
    n0.request(opt(24), @telnet.OptionSide::Remote, true),
  )
  let remote_queued = seq_apply(
    remote_requested,
    remote_requested.request(opt(24), @telnet.OptionSide::Remote, false),
  )
  let remote_accept = remote_queued.receive(
    neg_event(@telnet.NegotiationVerb::Will, 24),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(seq_send_count(remote_accept.actions) == 1)
  let remote_after = seq_apply(remote_queued, remote_accept)
  assert_true(
    remote_after.state_for(opt(24)).remote_state == @telnet.HalfState::Yes,
  )

  let local_requested = seq_apply(
    @telnet.Negotiator::new(),
    @telnet.Negotiator::new().request(opt(3), @telnet.OptionSide::Local, true),
  )
  let local_queued = seq_apply(
    local_requested,
    local_requested.request(opt(3), @telnet.OptionSide::Local, false),
  )
  let local_accept = local_queued.receive(
    neg_event(@telnet.NegotiationVerb::Do, 3),
    @telnet.PolicyDecision::Accept,
  )
  assert_true(seq_send_count(local_accept.actions) == 1)
  let local_after = seq_apply(local_queued, local_accept)
  assert_true(
    local_after.state_for(opt(3)).local_state == @telnet.HalfState::Yes,
  )
}

///|
test "negotiator sequence simultaneous local and remote enable share option independently" {
  let n0 = @telnet.Negotiator::new()
  let remote_request = n0.request(opt(0), @telnet.OptionSide::Remote, true)
  let n1 = seq_apply(n0, remote_request)
  let local_request = n1.request(opt(0), @telnet.OptionSide::Local, true)
  let n2 = seq_apply(n1, local_request)
  assert_true(
    n2.state_for(opt(0)) ==
    option_state(
      0,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
  )

  let remote_accept = n2.receive(
    neg_event(@telnet.NegotiationVerb::Will, 0),
    @telnet.PolicyDecision::Accept,
  )
  let n3 = seq_apply(n2, remote_accept)
  assert_true(
    n3.state_for(opt(0)).local_state == n2.state_for(opt(0)).local_state,
  )
  let local_accept = n3.receive(
    neg_event(@telnet.NegotiationVerb::Do, 0),
    @telnet.PolicyDecision::Accept,
  )
  let n4 = seq_apply(n3, local_accept)
  assert_true(
    n4.state_for(opt(0)) ==
    option_state(0, @telnet.HalfState::Yes, @telnet.HalfState::Yes),
  )
}

///|
test "negotiator sequence duplicate command storms settle without unbounded sends" {
  let mut n = @telnet.Negotiator::with_states([
    option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::Yes),
  ])
  let storm = [
    neg_event(@telnet.NegotiationVerb::Will, 1),
    neg_event(@telnet.NegotiationVerb::Will, 1),
    neg_event(@telnet.NegotiationVerb::Do, 1),
    neg_event(@telnet.NegotiationVerb::Do, 1),
    neg_event(@telnet.NegotiationVerb::Wont, 1),
    neg_event(@telnet.NegotiationVerb::Wont, 1),
    neg_event(@telnet.NegotiationVerb::Dont, 1),
    neg_event(@telnet.NegotiationVerb::Dont, 1),
  ]
  for event in storm {
    let t = n.receive(event, @telnet.PolicyDecision::Accept)
    seq_assert_bounded(t)
    n = n.apply(t)
  }
  assert_true(
    n.state_for(opt(1)) ==
    option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
  )

  let replay_wont = n.receive(
    neg_event(@telnet.NegotiationVerb::Wont, 1),
    @telnet.PolicyDecision::Accept,
  )
  let after_wont = seq_apply(n, replay_wont)
  assert_true(after_wont.state_for(opt(1)) == n.state_for(opt(1)))
  let replay_dont = after_wont.receive(
    neg_event(@telnet.NegotiationVerb::Dont, 1),
    @telnet.PolicyDecision::Accept,
  )
  seq_assert_bounded(replay_dont)
  assert_true(
    after_wont.apply(replay_dont).state_for(opt(1)) == n.state_for(opt(1)),
  )
}

///|
test "negotiator sequence interleaved options update only matching state" {
  let n0 = @telnet.Negotiator::new()
  let echo_pending = seq_apply(
    n0,
    n0.request(opt(1), @telnet.OptionSide::Remote, true),
  )
  let naws_pending = seq_apply(
    echo_pending,
    echo_pending.request(opt(31), @telnet.OptionSide::Local, true),
  )
  assert_true(
    naws_pending.state_for(opt(1)).remote_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
  )
  assert_true(
    naws_pending.state_for(opt(31)).local_state ==
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
  )

  let echo_accept = naws_pending.receive(
    neg_event(@telnet.NegotiationVerb::Will, 1),
    @telnet.PolicyDecision::Accept,
  )
  let n3 = seq_apply(naws_pending, echo_accept)
  assert_true(n3.state_for(opt(31)) == naws_pending.state_for(opt(31)))
  let naws_refuse = n3.receive(
    neg_event(@telnet.NegotiationVerb::Dont, 31),
    @telnet.PolicyDecision::Accept,
  )
  let n4 = seq_apply(n3, naws_refuse)
  assert_true(n4.state_for(opt(1)) == n3.state_for(opt(1)))
  assert_true(n4.state_for(opt(31)).local_state == @telnet.HalfState::No)
}
