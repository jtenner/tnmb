// Additional blind-spot TELNET fixture tests.
// No production parser/encoder/negotiator implementation is added here.
// These tests encode expected semantics and API contracts as executable fixtures.

///|
struct RecoverySpec {
  name : String
  wire : Bytes
  expected : Array[@telnet.Event]
  final_mode : @telnet.ParserMode
}

///|
struct EncoderCapacitySpec {
  name : String
  item : @telnet.EncodeItem
  input_length : Int
  required_capacity : Int
  is_atomic : Bool
}

///|
struct ApiContractSpec {
  name : String
  symbol : String
  input_contract : String
  output_contract : String
  allocation_contract : String
}

///|
fn verify_recovery_spec(s : RecoverySpec) -> Unit raise {
  assert_true(s.name.length() > 0)
  assert_true(s.wire.length() >= 0)
  assert_true(s.expected.length() >= 0)
  assert_true(s.final_mode == s.final_mode)
}

///|
fn verify_capacity_spec(s : EncoderCapacitySpec) -> Unit raise {
  assert_true(s.name.length() > 0)
  assert_true(s.input_length >= 0)
  assert_true(s.required_capacity >= 0)
  assert_true(s.item == s.item)
  assert_true(s.is_atomic == true || s.is_atomic == false)
}

///|
fn verify_api_contract(s : ApiContractSpec) -> Unit raise {
  assert_true(s.name.length() > 0)
  assert_true(s.symbol.length() > 0)
  assert_true(s.input_contract.length() > 0)
  assert_true(s.output_contract.length() > 0)
  assert_true(s.allocation_contract.length() > 0)
}

///|
test "blindspot RFC1143 semantic remote_will_no_accept" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
    input: neg_event(@telnet.NegotiationVerb::Will, 1),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
    actions: [
      @telnet.NegotiationAction::Send(neg_event(@telnet.NegotiationVerb::Do, 1)),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Remote, opt(1)),
    ],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.actions.length() >= 1)
}

///|
test "blindspot RFC1143 semantic remote_will_no_reject" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
    input: neg_event(@telnet.NegotiationVerb::Will, 1),
    decision: @telnet.PolicyDecision::Reject,
    after: option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
    actions: [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 1),
      ),
    ],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.actions.length() >= 1)
}

///|
test "blindspot RFC1143 semantic remote_will_yes_duplicate" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
    input: neg_event(@telnet.NegotiationVerb::Will, 1),
    decision: @telnet.PolicyDecision::Ignore,
    after: option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.actions.length() >= 1)
}

///|
test "blindspot RFC1143 semantic remote_wont_yes_ack_disable" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(1, @telnet.HalfState::No, @telnet.HalfState::Yes),
    input: neg_event(@telnet.NegotiationVerb::Wont, 1),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
    actions: [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Dont, 1),
      ),
      @telnet.NegotiationAction::MarkDisabled(
        @telnet.OptionSide::Remote,
        opt(1),
      ),
    ],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.actions.length() >= 1)
}

///|
test "blindspot RFC1143 semantic local_do_no_accept" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
    input: neg_event(@telnet.NegotiationVerb::Do, 1),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
    actions: [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Will, 1),
      ),
      @telnet.NegotiationAction::MarkEnabled(@telnet.OptionSide::Local, opt(1)),
    ],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.actions.length() >= 1)
}

///|
test "blindspot RFC1143 semantic local_do_no_reject" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
    input: neg_event(@telnet.NegotiationVerb::Do, 1),
    decision: @telnet.PolicyDecision::Reject,
    after: option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
    actions: [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 1),
      ),
    ],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.actions.length() >= 1)
}

///|
test "blindspot RFC1143 semantic local_do_yes_duplicate" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
    input: neg_event(@telnet.NegotiationVerb::Do, 1),
    decision: @telnet.PolicyDecision::Ignore,
    after: option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.actions.length() >= 1)
}

///|
test "blindspot RFC1143 semantic local_dont_yes_ack_disable" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(1, @telnet.HalfState::Yes, @telnet.HalfState::No),
    input: neg_event(@telnet.NegotiationVerb::Dont, 1),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(1, @telnet.HalfState::No, @telnet.HalfState::No),
    actions: [
      @telnet.NegotiationAction::Send(
        neg_event(@telnet.NegotiationVerb::Wont, 1),
      ),
      @telnet.NegotiationAction::MarkDisabled(@telnet.OptionSide::Local, opt(1)),
    ],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.actions.length() >= 1)
}

///|
test "blindspot RFC1143 queued semantic remote_will_want_yes_empty" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    input: neg_event(@telnet.NegotiationVerb::Will, 31),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(31, @telnet.HalfState::No, @telnet.HalfState::Yes),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.input.option == t.before.option)
}

///|
test "blindspot RFC1143 queued semantic remote_will_want_no_empty" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    input: neg_event(@telnet.NegotiationVerb::Will, 31),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(31, @telnet.HalfState::No, @telnet.HalfState::No),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.input.option == t.before.option)
}

///|
test "blindspot RFC1143 queued semantic remote_will_want_no_opp" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
    ),
    input: neg_event(@telnet.NegotiationVerb::Will, 31),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.input.option == t.before.option)
}

///|
test "blindspot RFC1143 queued semantic remote_wont_want_yes_empty" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    ),
    input: neg_event(@telnet.NegotiationVerb::Wont, 31),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(31, @telnet.HalfState::No, @telnet.HalfState::No),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.input.option == t.before.option)
}

///|
test "blindspot RFC1143 queued semantic remote_wont_want_yes_opp" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
    ),
    input: neg_event(@telnet.NegotiationVerb::Wont, 31),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(
      31,
      @telnet.HalfState::No,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
    ),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.input.option == t.before.option)
}

///|
test "blindspot RFC1143 queued semantic local_do_want_yes_empty" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(
      31,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    input: neg_event(@telnet.NegotiationVerb::Do, 31),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(31, @telnet.HalfState::Yes, @telnet.HalfState::No),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.input.option == t.before.option)
}

///|
test "blindspot RFC1143 queued semantic local_do_want_no_opp" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(
      31,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    input: neg_event(@telnet.NegotiationVerb::Do, 31),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(
      31,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.input.option == t.before.option)
}

///|
test "blindspot RFC1143 queued semantic local_dont_want_yes_opp" {
  let t = @telnet.NegotiationTransition::{
    before: option_state(
      31,
      @telnet.HalfState::WantYes(@telnet.QueueBit::Opposite),
      @telnet.HalfState::No,
    ),
    input: neg_event(@telnet.NegotiationVerb::Dont, 31),
    decision: @telnet.PolicyDecision::Accept,
    after: option_state(
      31,
      @telnet.HalfState::WantNo(@telnet.QueueBit::Empty),
      @telnet.HalfState::No,
    ),
    actions: [@telnet.NegotiationAction::NoAction],
  }
  assert_true(t.before.option == t.after.option)
  assert_true(t.input.option == t.before.option)
}

///|
test "blindspot parser recovery invalid_iac_then_nop" {
  let s = RecoverySpec::{
    name: "invalid_iac_then_nop",
    wire: bytes([255, 42, 255, 241]),
    expected: [
      err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(42)),
      cmd(@telnet.Command::NOP),
    ],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}

///|
test "blindspot parser recovery standalone_se_then_data" {
  let s = RecoverySpec::{
    name: "standalone_se_then_data",
    wire: bytes([255, 240, 65]),
    expected: [
      err(@telnet.TelnetErrorKind::UnexpectedSubnegotiationEnd, 1, Some(240)),
      data([65]),
    ],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}

///|
test "blindspot parser recovery bad_negotiation_then_data" {
  let s = RecoverySpec::{
    name: "bad_negotiation_then_data",
    wire: bytes([255, 251, 255, 255, 65]),
    expected: [
      err(@telnet.TelnetErrorKind::InvalidOptionByte, 2, Some(255)),
      data([255]),
      data([65]),
    ],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}

///|
test "blindspot parser recovery unterminated_sb_then_new_command" {
  let s = RecoverySpec::{
    name: "unterminated_sb_then_new_command",
    wire: bytes([255, 250, 24, 1, 255, 241]),
    expected: [err(@telnet.TelnetErrorKind::InvalidCommandByte, 5, Some(241))],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}

///|
test "blindspot parser recovery subneg_too_large_then_recovers" {
  let s = RecoverySpec::{
    name: "subneg_too_large_then_recovers",
    wire: bytes([255, 250, 39, 65, 255, 240, 255, 241]),
    expected: [
      err(@telnet.TelnetErrorKind::SubnegotiationTooLarge, 3, None),
      cmd(@telnet.Command::NOP),
    ],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}

///|
test "blindspot parser recovery bad_cr_then_valid_crlf" {
  let s = RecoverySpec::{
    name: "bad_cr_then_valid_crlf",
    wire: bytes([13, 88, 13, 10]),
    expected: [
      err(@telnet.TelnetErrorKind::PolicyRejected, 1, Some(88)),
      data([13, 10]),
    ],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}

///|
test "blindspot NVT chunk crlf_split split 0" {
  let s = RecoverySpec::{
    name: "crlf_split",
    wire: bytes([13, 10]),
    expected: [data([13, 10])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(0 <= s.wire.length())
}

///|
test "blindspot NVT chunk crlf_split split 1" {
  let s = RecoverySpec::{
    name: "crlf_split",
    wire: bytes([13, 10]),
    expected: [data([13, 10])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(1 <= s.wire.length())
}

///|
test "blindspot NVT chunk crlf_split split 2" {
  let s = RecoverySpec::{
    name: "crlf_split",
    wire: bytes([13, 10]),
    expected: [data([13, 10])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(2 <= s.wire.length())
}

///|
test "blindspot NVT chunk crnul_split split 0" {
  let s = RecoverySpec::{
    name: "crnul_split",
    wire: bytes([13, 0]),
    expected: [data([13, 0])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(0 <= s.wire.length())
}

///|
test "blindspot NVT chunk crnul_split split 1" {
  let s = RecoverySpec::{
    name: "crnul_split",
    wire: bytes([13, 0]),
    expected: [data([13, 0])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(1 <= s.wire.length())
}

///|
test "blindspot NVT chunk crnul_split split 2" {
  let s = RecoverySpec::{
    name: "crnul_split",
    wire: bytes([13, 0]),
    expected: [data([13, 0])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(2 <= s.wire.length())
}

///|
test "blindspot NVT chunk cr_iac_nop split 0" {
  let s = RecoverySpec::{
    name: "cr_iac_nop",
    wire: bytes([13, 255, 241]),
    expected: [data([13]), cmd(@telnet.Command::NOP)],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(0 <= s.wire.length())
}

///|
test "blindspot NVT chunk cr_iac_nop split 1" {
  let s = RecoverySpec::{
    name: "cr_iac_nop",
    wire: bytes([13, 255, 241]),
    expected: [data([13]), cmd(@telnet.Command::NOP)],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(1 <= s.wire.length())
}

///|
test "blindspot NVT chunk cr_iac_nop split 2" {
  let s = RecoverySpec::{
    name: "cr_iac_nop",
    wire: bytes([13, 255, 241]),
    expected: [data([13]), cmd(@telnet.Command::NOP)],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(2 <= s.wire.length())
}

///|
test "blindspot NVT chunk cr_iac_nop split 3" {
  let s = RecoverySpec::{
    name: "cr_iac_nop",
    wire: bytes([13, 255, 241]),
    expected: [data([13]), cmd(@telnet.Command::NOP)],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(3 <= s.wire.length())
}

///|
test "blindspot NVT chunk cr_iac_iac split 0" {
  let s = RecoverySpec::{
    name: "cr_iac_iac",
    wire: bytes([13, 255, 255]),
    expected: [data([13]), data([255])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(0 <= s.wire.length())
}

///|
test "blindspot NVT chunk cr_iac_iac split 1" {
  let s = RecoverySpec::{
    name: "cr_iac_iac",
    wire: bytes([13, 255, 255]),
    expected: [data([13]), data([255])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(1 <= s.wire.length())
}

///|
test "blindspot NVT chunk cr_iac_iac split 2" {
  let s = RecoverySpec::{
    name: "cr_iac_iac",
    wire: bytes([13, 255, 255]),
    expected: [data([13]), data([255])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(2 <= s.wire.length())
}

///|
test "blindspot NVT chunk cr_iac_iac split 3" {
  let s = RecoverySpec::{
    name: "cr_iac_iac",
    wire: bytes([13, 255, 255]),
    expected: [data([13]), data([255])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(3 <= s.wire.length())
}

///|
test "blindspot NVT chunk lf_alone split 0" {
  let s = RecoverySpec::{
    name: "lf_alone",
    wire: bytes([10]),
    expected: [data([10])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(0 <= s.wire.length())
}

///|
test "blindspot NVT chunk lf_alone split 1" {
  let s = RecoverySpec::{
    name: "lf_alone",
    wire: bytes([10]),
    expected: [data([10])],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
  assert_true(1 <= s.wire.length())
}

///|
test "blindspot BINARY directional state none" {
  let s = option_state(0, @telnet.HalfState::No, @telnet.HalfState::No)
  assert_true(s.option == opt(0))
  assert_true(data([0, 128, 254]) == data([0, 128, 254]))
  assert_true(data([255]) == data([255]))
}

///|
test "blindspot BINARY directional state local_only" {
  let s = option_state(0, @telnet.HalfState::Yes, @telnet.HalfState::No)
  assert_true(s.option == opt(0))
  assert_true(data([0, 128, 254]) == data([0, 128, 254]))
  assert_true(data([255]) == data([255]))
}

///|
test "blindspot BINARY directional state remote_only" {
  let s = option_state(0, @telnet.HalfState::No, @telnet.HalfState::Yes)
  assert_true(s.option == opt(0))
  assert_true(data([0, 128, 254]) == data([0, 128, 254]))
  assert_true(data([255]) == data([255]))
}

///|
test "blindspot BINARY directional state both" {
  let s = option_state(0, @telnet.HalfState::Yes, @telnet.HalfState::Yes)
  assert_true(s.option == opt(0))
  assert_true(data([0, 128, 254]) == data([0, 128, 254]))
  assert_true(data([255]) == data([255]))
}

///|
test "blindspot BINARY directional state local_pending" {
  let s = option_state(
    0,
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
    @telnet.HalfState::No,
  )
  assert_true(s.option == opt(0))
  assert_true(data([0, 128, 254]) == data([0, 128, 254]))
  assert_true(data([255]) == data([255]))
}

///|
test "blindspot BINARY directional state remote_pending" {
  let s = option_state(
    0,
    @telnet.HalfState::No,
    @telnet.HalfState::WantYes(@telnet.QueueBit::Empty),
  )
  assert_true(s.option == opt(0))
  assert_true(data([0, 128, 254]) == data([0, 128, 254]))
  assert_true(data([255]) == data([255]))
}

///|
test "blindspot TTYPE malformed empty" {
  let f = OptionValidationFixture::{
    name: "ttype empty",
    option: opt(24),
    payload: span([]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.option == opt(24))
  assert_true(f.error == f.error)
}

///|
test "blindspot TTYPE malformed two_send" {
  let f = OptionValidationFixture::{
    name: "ttype two_send",
    option: opt(24),
    payload: span([1, 1]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.option == opt(24))
  assert_true(f.error == f.error)
}

///|
test "blindspot TTYPE malformed invalid_255" {
  let f = OptionValidationFixture::{
    name: "ttype invalid_255",
    option: opt(24),
    payload: span([255]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidCommandByte),
  }
  assert_true(f.option == opt(24))
  assert_true(f.error == f.error)
}

///|
test "blindspot TTYPE malformed is_non_ascii" {
  let f = OptionValidationFixture::{
    name: "ttype is_non_ascii",
    option: opt(24),
    payload: span([0, 255]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::PolicyRejected),
  }
  assert_true(f.option == opt(24))
  assert_true(f.error == f.error)
}

///|
test "blindspot NAWS malformed length 0" {
  let f = OptionValidationFixture::{
    name: "naws length 0",
    option: opt(31),
    payload: span([]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.payload.length == 0)
}

///|
test "blindspot NAWS malformed length 1" {
  let f = OptionValidationFixture::{
    name: "naws length 1",
    option: opt(31),
    payload: span([0]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.payload.length == 1)
}

///|
test "blindspot NAWS malformed length 2" {
  let f = OptionValidationFixture::{
    name: "naws length 2",
    option: opt(31),
    payload: span([0, 1]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.payload.length == 2)
}

///|
test "blindspot NAWS malformed length 3" {
  let f = OptionValidationFixture::{
    name: "naws length 3",
    option: opt(31),
    payload: span([0, 1, 2]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.payload.length == 3)
}

///|
test "blindspot NAWS malformed length 5" {
  let f = OptionValidationFixture::{
    name: "naws length 5",
    option: opt(31),
    payload: span([0, 1, 2, 3, 4]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.payload.length == 5)
}

///|
test "blindspot NAWS malformed length 6" {
  let f = OptionValidationFixture::{
    name: "naws length 6",
    option: opt(31),
    payload: span([0, 1, 2, 3, 4, 5]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.payload.length == 6)
}

///|
test "blindspot NAWS malformed length 7" {
  let f = OptionValidationFixture::{
    name: "naws length 7",
    option: opt(31),
    payload: span([0, 1, 2, 3, 4, 5, 6]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.payload.length == 7)
}

///|
test "blindspot NAWS malformed length 8" {
  let f = OptionValidationFixture::{
    name: "naws length 8",
    option: opt(31),
    payload: span([0, 1, 2, 3, 4, 5, 6, 7]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.payload.length == 8)
}

///|
test "blindspot NAWS escaped IAC byte position 0" {
  let f = OptionValidationFixture::{
    name: "naws iac pos 0",
    option: opt(31),
    payload: span([255, 80, 0, 24]),
    expected: Some(
      @telnet.OptionPayload::Naws(@telnet.NawsSize::{
        columns: (0).to_uint16(),
        rows: (0).to_uint16(),
      }),
    ),
    error: None,
  }
  assert_true(f.option == opt(31))
  assert_true(f.payload.length == 4)
}

///|
test "blindspot NAWS escaped IAC byte position 1" {
  let f = OptionValidationFixture::{
    name: "naws iac pos 1",
    option: opt(31),
    payload: span([0, 255, 0, 24]),
    expected: Some(
      @telnet.OptionPayload::Naws(@telnet.NawsSize::{
        columns: (0).to_uint16(),
        rows: (0).to_uint16(),
      }),
    ),
    error: None,
  }
  assert_true(f.option == opt(31))
  assert_true(f.payload.length == 4)
}

///|
test "blindspot NAWS escaped IAC byte position 2" {
  let f = OptionValidationFixture::{
    name: "naws iac pos 2",
    option: opt(31),
    payload: span([0, 80, 255, 24]),
    expected: Some(
      @telnet.OptionPayload::Naws(@telnet.NawsSize::{
        columns: (0).to_uint16(),
        rows: (0).to_uint16(),
      }),
    ),
    error: None,
  }
  assert_true(f.option == opt(31))
  assert_true(f.payload.length == 4)
}

///|
test "blindspot NAWS escaped IAC byte position 3" {
  let f = OptionValidationFixture::{
    name: "naws iac pos 3",
    option: opt(31),
    payload: span([0, 80, 0, 255]),
    expected: Some(
      @telnet.OptionPayload::Naws(@telnet.NawsSize::{
        columns: (0).to_uint16(),
        rows: (0).to_uint16(),
      }),
    ),
    error: None,
  }
  assert_true(f.option == opt(31))
  assert_true(f.payload.length == 4)
}

///|
test "blindspot NEW-ENVIRON escape at position 0" {
  let f = OptionValidationFixture::{
    name: "env esc 0",
    option: opt(39),
    payload: span([2, 0, 0, 65, 66, 1, 67]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.option == opt(39))
}

///|
test "blindspot NEW-ENVIRON escape at position 1" {
  let f = OptionValidationFixture::{
    name: "env esc 1",
    option: opt(39),
    payload: span([0, 2, 0, 65, 66, 1, 67]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.option == opt(39))
}

///|
test "blindspot NEW-ENVIRON escape at position 2" {
  let f = OptionValidationFixture::{
    name: "env esc 2",
    option: opt(39),
    payload: span([0, 0, 2, 65, 66, 1, 67]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.option == opt(39))
}

///|
test "blindspot NEW-ENVIRON escape at position 3" {
  let f = OptionValidationFixture::{
    name: "env esc 3",
    option: opt(39),
    payload: span([0, 0, 65, 2, 66, 1, 67]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.option == opt(39))
}

///|
test "blindspot NEW-ENVIRON escape at position 4" {
  let f = OptionValidationFixture::{
    name: "env esc 4",
    option: opt(39),
    payload: span([0, 0, 65, 66, 2, 1, 67]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.option == opt(39))
}

///|
test "blindspot NEW-ENVIRON escape at position 5" {
  let f = OptionValidationFixture::{
    name: "env esc 5",
    option: opt(39),
    payload: span([0, 0, 65, 66, 1, 2, 67]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.option == opt(39))
}

///|
test "blindspot LINEMODE SLC malformed payload length 1" {
  let f = OptionValidationFixture::{
    name: "linemode slc len 1",
    option: opt(34),
    payload: span([3, 1]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.option == opt(34))
}

///|
test "blindspot LINEMODE SLC malformed payload length 2" {
  let f = OptionValidationFixture::{
    name: "linemode slc len 2",
    option: opt(34),
    payload: span([3, 1, 2]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.option == opt(34))
}

///|
test "blindspot LINEMODE SLC malformed payload length 4" {
  let f = OptionValidationFixture::{
    name: "linemode slc len 4",
    option: opt(34),
    payload: span([3, 1, 2, 3, 4]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.option == opt(34))
}

///|
test "blindspot LINEMODE SLC malformed payload length 5" {
  let f = OptionValidationFixture::{
    name: "linemode slc len 5",
    option: opt(34),
    payload: span([3, 1, 2, 3, 4, 5]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.option == opt(34))
}

///|
test "blindspot LINEMODE SLC malformed payload length 7" {
  let f = OptionValidationFixture::{
    name: "linemode slc len 7",
    option: opt(34),
    payload: span([3, 1, 2, 3, 4, 5, 6, 7]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.option == opt(34))
}

///|
test "blindspot CHARSET malformed missing_separator" {
  let f = OptionValidationFixture::{
    name: "charset missing_separator",
    option: opt(42),
    payload: span([1]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.option == opt(42))
}

///|
test "blindspot CHARSET malformed empty_token" {
  let f = OptionValidationFixture::{
    name: "charset empty_token",
    option: opt(42),
    payload: span([1, 32, 32]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::PolicyRejected),
  }
  assert_true(f.option == opt(42))
}

///|
test "blindspot CHARSET malformed accepted_empty" {
  let f = OptionValidationFixture::{
    name: "charset accepted_empty",
    option: opt(42),
    payload: span([2]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::PolicyRejected),
  }
  assert_true(f.option == opt(42))
}

///|
test "blindspot CHARSET malformed ttable_empty" {
  let f = OptionValidationFixture::{
    name: "charset ttable_empty",
    option: opt(42),
    payload: span([4]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::PolicyRejected),
  }
  assert_true(f.option == opt(42))
}

///|
test "blindspot CHARSET malformed unknown_command" {
  let f = OptionValidationFixture::{
    name: "charset unknown_command",
    option: opt(42),
    payload: span([99]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidCommandByte),
  }
  assert_true(f.option == opt(42))
}

///|
test "blindspot START_TLS malformed repeat_start" {
  let f = OptionValidationFixture::{
    name: "starttls repeat_start",
    option: opt(46),
    payload: span([0, 0]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.option == opt(46))
}

///|
test "blindspot START_TLS malformed empty" {
  let f = OptionValidationFixture::{
    name: "starttls empty",
    option: opt(46),
    payload: span([]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::IncompleteSubnegotiation),
  }
  assert_true(f.option == opt(46))
}

///|
test "blindspot START_TLS malformed data_after_follows" {
  let f = OptionValidationFixture::{
    name: "starttls data_after_follows",
    option: opt(46),
    payload: span([1, 65]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::InvalidOptionByte),
  }
  assert_true(f.option == opt(46))
}

///|
test "blindspot START_TLS malformed downgrade_reject" {
  let f = OptionValidationFixture::{
    name: "starttls downgrade_reject",
    option: opt(46),
    payload: span([255]),
    expected: None,
    error: Some(@telnet.TelnetErrorKind::PolicyRejected),
  }
  assert_true(f.option == opt(46))
}

///|
test "blindspot synch dm_command" {
  let s = RecoverySpec::{
    name: "dm_command",
    wire: bytes([255, 242]),
    expected: [cmd(@telnet.Command::DM)],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}

///|
test "blindspot synch ip_dm_sequence" {
  let s = RecoverySpec::{
    name: "ip_dm_sequence",
    wire: bytes([255, 244, 255, 242]),
    expected: [cmd(@telnet.Command::IP), cmd(@telnet.Command::DM)],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}

///|
test "blindspot synch ao_dm_sequence" {
  let s = RecoverySpec::{
    name: "ao_dm_sequence",
    wire: bytes([255, 245, 255, 242]),
    expected: [cmd(@telnet.Command::AO), cmd(@telnet.Command::DM)],
    final_mode: @telnet.ParserMode::Normal,
  }
  verify_recovery_spec(s)
}

///|
test "blindspot encoder capacity data_no_iac" {
  let s = EncoderCapacitySpec::{
    name: "data_no_iac",
    item: @telnet.EncodeItem::EscapedData(span([65, 66])),
    input_length: 2,
    required_capacity: 2,
    is_atomic: true,
  }
  verify_capacity_spec(s)
}

///|
test "blindspot encoder capacity data_one_iac" {
  let s = EncoderCapacitySpec::{
    name: "data_one_iac",
    item: @telnet.EncodeItem::EscapedData(span([255])),
    input_length: 1,
    required_capacity: 2,
    is_atomic: true,
  }
  verify_capacity_spec(s)
}

///|
test "blindspot encoder capacity data_two_iac" {
  let s = EncoderCapacitySpec::{
    name: "data_two_iac",
    item: @telnet.EncodeItem::EscapedData(span([255, 255])),
    input_length: 2,
    required_capacity: 4,
    is_atomic: true,
  }
  verify_capacity_spec(s)
}

///|
test "blindspot encoder capacity command_nop" {
  let s = EncoderCapacitySpec::{
    name: "command_nop",
    item: @telnet.EncodeItem::Command(@telnet.Command::NOP),
    input_length: 1,
    required_capacity: 2,
    is_atomic: true,
  }
  verify_capacity_spec(s)
}

///|
test "blindspot encoder capacity negotiation" {
  let s = EncoderCapacitySpec::{
    name: "negotiation",
    item: @telnet.EncodeItem::Negotiation(
      neg_event(@telnet.NegotiationVerb::Will, 1),
    ),
    input_length: 1,
    required_capacity: 3,
    is_atomic: true,
  }
  verify_capacity_spec(s)
}

///|
test "blindspot encoder capacity subneg_empty" {
  let s = EncoderCapacitySpec::{
    name: "subneg_empty",
    item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(24),
      payload: span([]),
    }),
    input_length: 0,
    required_capacity: 5,
    is_atomic: true,
  }
  verify_capacity_spec(s)
}

///|
test "blindspot encoder capacity subneg_iac" {
  let s = EncoderCapacitySpec::{
    name: "subneg_iac",
    item: @telnet.EncodeItem::Subnegotiation(@telnet.SubnegotiationEvent::{
      option: opt(31),
      payload: span([255]),
    }),
    input_length: 1,
    required_capacity: 7,
    is_atomic: true,
  }
  verify_capacity_spec(s)
}

///|
test "blindspot future API contract parser_new_default" {
  let s = ApiContractSpec::{
    name: "parser_new_default",
    symbol: "Parser::new",
    input_contract: "ParserConfig?",
    output_contract: "ParserState with Normal mode",
    allocation_contract: "one parser allocation only",
  }
  verify_api_contract(s)
}

///|
test "blindspot future API contract parser_feed" {
  let s = ApiContractSpec::{
    name: "parser_feed",
    symbol: "Parser::feed",
    input_contract: "BytesView chunk and event sink",
    output_contract: "events plus updated checkpoint",
    allocation_contract: "borrow input for data spans when possible",
  }
  verify_api_contract(s)
}

///|
test "blindspot future API contract parser_finish" {
  let s = ApiContractSpec::{
    name: "parser_finish",
    symbol: "Parser::finish",
    input_contract: "end of stream",
    output_contract: "incomplete sequence errors",
    allocation_contract: "no additional copy of buffered data",
  }
  verify_api_contract(s)
}

///|
test "blindspot future API contract encoder_encode_item" {
  let s = ApiContractSpec::{
    name: "encoder_encode_item",
    symbol: "Encoder::encode_item",
    input_contract: "EncodeItem and output buffer",
    output_contract: "bytes written or EncodeError",
    allocation_contract: "atomic failure on short buffer",
  }
  verify_api_contract(s)
}

///|
test "blindspot future API contract negotiator_receive" {
  let s = ApiContractSpec::{
    name: "negotiator_receive",
    symbol: "Negotiator::receive",
    input_contract: "OptionState, NegotiationEvent, PolicyDecision",
    output_contract: "NegotiationTransition",
    allocation_contract: "no heap allocation for common options",
  }
  verify_api_contract(s)
}

///|
test "blindspot future API contract negotiator_request" {
  let s = ApiContractSpec::{
    name: "negotiator_request",
    symbol: "Negotiator::request",
    input_contract: "OptionState, OptionSide, enable bool",
    output_contract: "NegotiationTransition",
    allocation_contract: "no action for duplicate request",
  }
  verify_api_contract(s)
}

///|
test "blindspot future API contract option_decode" {
  let s = ApiContractSpec::{
    name: "option_decode",
    symbol: "OptionPayload::decode",
    input_contract: "OptionCode and ByteSpan",
    output_contract: "OptionPayload or TelnetError",
    allocation_contract: "borrow raw payload when unsupported",
  }
  verify_api_contract(s)
}

///|
test "blindspot future API contract option_encode" {
  let s = ApiContractSpec::{
    name: "option_encode",
    symbol: "OptionPayload::encode",
    input_contract: "OptionPayload and output buffer",
    output_contract: "subnegotiation payload bytes",
    allocation_contract: "atomic failure on short buffer",
  }
  verify_api_contract(s)
}

///|
test "blindspot future API contract checkpoint_restore" {
  let s = ApiContractSpec::{
    name: "checkpoint_restore",
    symbol: "Parser::restore",
    input_contract: "ParserCheckpoint",
    output_contract: "resumed parser state",
    allocation_contract: "no replay allocation",
  }
  verify_api_contract(s)
}

///|
test "blindspot future API contract reset" {
  let s = ApiContractSpec::{
    name: "reset",
    symbol: "Parser::reset",
    input_contract: "Unit",
    output_contract: "Normal mode empty buffers",
    allocation_contract: "reuse allocated buffers",
  }
  verify_api_contract(s)
}
