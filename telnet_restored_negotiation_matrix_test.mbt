// Restored RFC1143/Q-method matrix coverage rewritten as exact production negotiator assertions.

///|
fn restored_neg_assert_receive(
  before : @telnet.OptionState,
  input : @telnet.NegotiationEvent,
  decision : @telnet.PolicyDecision,
  expected_after : @telnet.OptionState,
  expected_actions : Array[@telnet.NegotiationAction],
) -> Unit raise {
  let negotiator = @telnet.Negotiator::with_states([before])
  let transition = negotiator.receive(input, decision)
  assert_true(transition.before == before)
  assert_true(transition.input == input)
  assert_true(transition.decision == decision)
  assert_true(transition.after == expected_after)
  assert_true(transition.actions == expected_actions)
  let applied = negotiator.apply(transition)
  assert_true(applied.state_for(before.option) == expected_after)
}

///|
fn restored_neg_assert_request(
  before : @telnet.OptionState,
  side : @telnet.OptionSide,
  enable : Bool,
  expected_input : @telnet.NegotiationEvent,
  expected_after : @telnet.OptionState,
  expected_actions : Array[@telnet.NegotiationAction],
) -> Unit raise {
  let negotiator = @telnet.Negotiator::with_states([before])
  let transition = negotiator.request(before.option, side, enable)
  assert_true(transition.before == before)
  assert_true(transition.input == expected_input)
  assert_true(transition.decision == @telnet.PolicyDecision::Accept)
  assert_true(transition.after == expected_after)
  assert_true(transition.actions == expected_actions)
}

///|
test "restored q matrix remote no receives WILL with accept" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    [
      @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 7)),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Remote, opt(7)),
    ],
  )
}

///|
test "restored q matrix remote no receives WONT with accept" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote no receives WILL with reject" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix remote no receives WONT with reject" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote no receives WILL with ignore" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix remote no receives WONT with ignore" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote yes receives WILL with accept" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix remote yes receives WONT with accept" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote yes receives WILL with reject" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix remote yes receives WONT with reject" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote yes receives WILL with ignore" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix remote yes receives WONT with ignore" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_no_empty receives WILL with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    [
      @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 7)),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Remote, opt(7)),
    ],
  )
}

///|
test "restored q matrix remote want_no_empty receives WONT with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_no_empty receives WILL with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Reject,
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_no_empty receives WONT with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_no_empty receives WILL with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix remote want_no_empty receives WONT with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_no_opposite receives WILL with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    [
      @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 7)),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Remote, opt(7)),
    ],
  )
}

///|
test "restored q matrix remote want_no_opposite receives WONT with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_no_opposite receives WILL with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Reject,
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_no_opposite receives WONT with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_no_opposite receives WILL with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix remote want_no_opposite receives WONT with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_yes_empty receives WILL with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    [
      @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 7)),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Remote, opt(7)),
    ],
  )
}

///|
test "restored q matrix remote want_yes_empty receives WONT with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_yes_empty receives WILL with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Reject,
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_yes_empty receives WONT with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_yes_empty receives WILL with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix remote want_yes_empty receives WONT with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_yes_opposite receives WILL with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::Yes),
    [
      @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 7)),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Remote, opt(7)),
    ],
  )
}

///|
test "restored q matrix remote want_yes_opposite receives WONT with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_yes_opposite receives WILL with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Reject,
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_yes_opposite receives WONT with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix remote want_yes_opposite receives WILL with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Will, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix remote want_yes_opposite receives WONT with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    neg_event(@telnet.NegotiationVerb::Wont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(7),
      ),
    ],
  )
}

///|
test "restored q matrix local no receives DO with accept" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 7),
      ),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local no receives DONT with accept" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local no receives DO with reject" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix local no receives DONT with reject" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local no receives DO with ignore" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix local no receives DONT with ignore" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local yes receives DO with accept" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix local yes receives DONT with accept" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local yes receives DO with reject" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix local yes receives DONT with reject" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local yes receives DO with ignore" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix local yes receives DONT with ignore" {
  restored_neg_assert_receive(
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_no_empty receives DO with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 7),
      ),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_no_empty receives DONT with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_no_empty receives DO with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Reject,
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix local want_no_empty receives DONT with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_no_empty receives DO with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix local want_no_empty receives DONT with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_no_opposite receives DO with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 7),
      ),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_no_opposite receives DONT with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_no_opposite receives DO with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Reject,
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix local want_no_opposite receives DONT with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_no_opposite receives DO with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix local want_no_opposite receives DONT with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_yes_empty receives DO with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 7),
      ),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_yes_empty receives DONT with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_yes_empty receives DO with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Reject,
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix local want_yes_empty receives DONT with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_yes_empty receives DO with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix local want_yes_empty receives DONT with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_yes_opposite receives DO with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::Yes, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 7),
      ),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_yes_opposite receives DONT with accept" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Accept,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_yes_opposite receives DO with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Reject,
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
    ],
  )
}

///|
test "restored q matrix local want_yes_opposite receives DONT with reject" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Reject,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored q matrix local want_yes_opposite receives DO with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Do, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored q matrix local want_yes_opposite receives DONT with ignore" {
  restored_neg_assert_receive(
    option_state(
      7,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    neg_event(@telnet.NegotiationVerb::Dont, 7),
    @telnet.PolicyDecision::Ignore,
    option_state(7, @telnet.HalfState::No, @telnet.HalfState::No),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 7),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(7)),
    ],
  )
}

///|
test "restored request matrix remote no enable" {
  restored_neg_assert_request(
    option_state(8, @telnet.HalfState::No, @telnet.HalfState::No),
    @telnet.OptionSide::Remote,
    true,
    neg_event(@telnet.NegotiationVerb::Do, 8),
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    [@telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 8))],
  )
}

///|
test "restored request matrix remote no disable" {
  restored_neg_assert_request(
    option_state(8, @telnet.HalfState::No, @telnet.HalfState::No),
    @telnet.OptionSide::Remote,
    false,
    neg_event(@telnet.NegotiationVerb::Dont, 8),
    option_state(8, @telnet.HalfState::No, @telnet.HalfState::No),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored request matrix local no enable" {
  restored_neg_assert_request(
    option_state(8, @telnet.HalfState::No, @telnet.HalfState::No),
    @telnet.OptionSide::Local,
    true,
    neg_event(@telnet.NegotiationVerb::Will, 8),
    option_state(
      8,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 8),
      ),
    ],
  )
}

///|
test "restored request matrix local no disable" {
  restored_neg_assert_request(
    option_state(8, @telnet.HalfState::No, @telnet.HalfState::No),
    @telnet.OptionSide::Local,
    false,
    neg_event(@telnet.NegotiationVerb::Wont, 8),
    option_state(8, @telnet.HalfState::No, @telnet.HalfState::No),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored request matrix remote yes enable" {
  restored_neg_assert_request(
    option_state(8, @telnet.HalfState::No, @telnet.HalfState::Yes),
    @telnet.OptionSide::Remote,
    true,
    neg_event(@telnet.NegotiationVerb::Do, 8),
    option_state(8, @telnet.HalfState::No, @telnet.HalfState::Yes),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored request matrix remote yes disable" {
  restored_neg_assert_request(
    option_state(8, @telnet.HalfState::No, @telnet.HalfState::Yes),
    @telnet.OptionSide::Remote,
    false,
    neg_event(@telnet.NegotiationVerb::Dont, 8),
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 8),
      ),
    ],
  )
}

///|
test "restored request matrix local yes enable" {
  restored_neg_assert_request(
    option_state(8, @telnet.HalfState::Yes, @telnet.HalfState::No),
    @telnet.OptionSide::Local,
    true,
    neg_event(@telnet.NegotiationVerb::Will, 8),
    option_state(8, @telnet.HalfState::Yes, @telnet.HalfState::No),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored request matrix local yes disable" {
  restored_neg_assert_request(
    option_state(8, @telnet.HalfState::Yes, @telnet.HalfState::No),
    @telnet.OptionSide::Local,
    false,
    neg_event(@telnet.NegotiationVerb::Wont, 8),
    option_state(
      8,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 8),
      ),
    ],
  )
}

///|
test "restored request matrix remote want_no_empty enable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    @telnet.OptionSide::Remote,
    true,
    neg_event(@telnet.NegotiationVerb::Do, 8),
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    [@telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 8))],
  )
}

///|
test "restored request matrix remote want_no_empty disable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    @telnet.OptionSide::Remote,
    false,
    neg_event(@telnet.NegotiationVerb::Dont, 8),
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 8),
      ),
    ],
  )
}

///|
test "restored request matrix local want_no_empty enable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    @telnet.OptionSide::Local,
    true,
    neg_event(@telnet.NegotiationVerb::Will, 8),
    option_state(
      8,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 8),
      ),
    ],
  )
}

///|
test "restored request matrix local want_no_empty disable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    @telnet.OptionSide::Local,
    false,
    neg_event(@telnet.NegotiationVerb::Wont, 8),
    option_state(
      8,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 8),
      ),
    ],
  )
}

///|
test "restored request matrix remote want_no_opposite enable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    @telnet.OptionSide::Remote,
    true,
    neg_event(@telnet.NegotiationVerb::Do, 8),
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    [@telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 8))],
  )
}

///|
test "restored request matrix remote want_no_opposite disable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    @telnet.OptionSide::Remote,
    false,
    neg_event(@telnet.NegotiationVerb::Dont, 8),
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 8),
      ),
    ],
  )
}

///|
test "restored request matrix local want_no_opposite enable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    @telnet.OptionSide::Local,
    true,
    neg_event(@telnet.NegotiationVerb::Will, 8),
    option_state(
      8,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 8),
      ),
    ],
  )
}

///|
test "restored request matrix local want_no_opposite disable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    @telnet.OptionSide::Local,
    false,
    neg_event(@telnet.NegotiationVerb::Wont, 8),
    option_state(
      8,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 8),
      ),
    ],
  )
}

///|
test "restored request matrix remote want_yes_empty enable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    @telnet.OptionSide::Remote,
    true,
    neg_event(@telnet.NegotiationVerb::Do, 8),
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    [@telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 8))],
  )
}

///|
test "restored request matrix remote want_yes_empty disable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    @telnet.OptionSide::Remote,
    false,
    neg_event(@telnet.NegotiationVerb::Dont, 8),
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored request matrix local want_yes_empty enable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    @telnet.OptionSide::Local,
    true,
    neg_event(@telnet.NegotiationVerb::Will, 8),
    option_state(
      8,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 8),
      ),
    ],
  )
}

///|
test "restored request matrix local want_yes_empty disable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    @telnet.OptionSide::Local,
    false,
    neg_event(@telnet.NegotiationVerb::Wont, 8),
    option_state(
      8,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    [@telnet.NegotiationAction::NoAction],
  )
}

///|
test "restored request matrix remote want_yes_opposite enable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    @telnet.OptionSide::Remote,
    true,
    neg_event(@telnet.NegotiationVerb::Do, 8),
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    [@telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 8))],
  )
}

///|
test "restored request matrix remote want_yes_opposite disable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    @telnet.OptionSide::Remote,
    false,
    neg_event(@telnet.NegotiationVerb::Dont, 8),
    option_state(
      8,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 8),
      ),
    ],
  )
}

///|
test "restored request matrix local want_yes_opposite enable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    @telnet.OptionSide::Local,
    true,
    neg_event(@telnet.NegotiationVerb::Will, 8),
    option_state(
      8,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 8),
      ),
    ],
  )
}

///|
test "restored request matrix local want_yes_opposite disable" {
  restored_neg_assert_request(
    option_state(
      8,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    @telnet.OptionSide::Local,
    false,
    neg_event(@telnet.NegotiationVerb::Wont, 8),
    option_state(
      8,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 8),
      ),
    ],
  )
}
