// Additional TELNET option registry mapping tests.

///|
fn assert_known_option_roundtrip(
  code : Int,
  known : @telnet.KnownOption,
) -> Unit raise {
  assert_true(known.to_code() == opt(code))
  assert_true(@telnet.KnownOption::from_code(opt(code)) == known)
  restored_gen_assert_parse([255, 253, code], [
    neg(@telnet.NegotiationVerb::Do, code),
  ])
}

///|
test "all modeled IANA registry options map and parse as negotiation triplets" {
  let cases = [
    OptionCase::{ byte: 0, known: @telnet.KnownOption::Binary },
    OptionCase::{ byte: 1, known: @telnet.KnownOption::Echo },
    OptionCase::{ byte: 2, known: @telnet.KnownOption::Reconnection },
    OptionCase::{ byte: 3, known: @telnet.KnownOption::SuppressGoAhead },
    OptionCase::{
      byte: 4,
      known: @telnet.KnownOption::ApproxMessageSizeNegotiation,
    },
    OptionCase::{ byte: 5, known: @telnet.KnownOption::Status },
    OptionCase::{ byte: 6, known: @telnet.KnownOption::TimingMark },
    OptionCase::{
      byte: 7,
      known: @telnet.KnownOption::RemoteControlledTransAndEcho,
    },
    OptionCase::{ byte: 8, known: @telnet.KnownOption::OutputLineWidth },
    OptionCase::{ byte: 9, known: @telnet.KnownOption::OutputPageSize },
    OptionCase::{
      byte: 10,
      known: @telnet.KnownOption::OutputCarriageReturnDisposition,
    },
    OptionCase::{
      byte: 11,
      known: @telnet.KnownOption::OutputHorizontalTabStops,
    },
    OptionCase::{
      byte: 12,
      known: @telnet.KnownOption::OutputHorizontalTabDisposition,
    },
    OptionCase::{
      byte: 13,
      known: @telnet.KnownOption::OutputFormfeedDisposition,
    },
    OptionCase::{ byte: 14, known: @telnet.KnownOption::OutputVerticalTabStops },
    OptionCase::{
      byte: 15,
      known: @telnet.KnownOption::OutputVerticalTabDisposition,
    },
    OptionCase::{
      byte: 16,
      known: @telnet.KnownOption::OutputLinefeedDisposition,
    },
    OptionCase::{ byte: 17, known: @telnet.KnownOption::ExtendedAscii },
    OptionCase::{ byte: 18, known: @telnet.KnownOption::Logout },
    OptionCase::{ byte: 19, known: @telnet.KnownOption::ByteMacro },
    OptionCase::{ byte: 20, known: @telnet.KnownOption::DataEntryTerminal },
    OptionCase::{ byte: 21, known: @telnet.KnownOption::Supdup },
    OptionCase::{ byte: 22, known: @telnet.KnownOption::SupdupOutput },
    OptionCase::{ byte: 23, known: @telnet.KnownOption::SendLocation },
    OptionCase::{ byte: 24, known: @telnet.KnownOption::TerminalType },
    OptionCase::{ byte: 25, known: @telnet.KnownOption::EndOfRecord },
    OptionCase::{
      byte: 26,
      known: @telnet.KnownOption::TacacsUserIdentification,
    },
    OptionCase::{ byte: 27, known: @telnet.KnownOption::OutputMarking },
    OptionCase::{ byte: 28, known: @telnet.KnownOption::TerminalLocationNumber },
    OptionCase::{ byte: 29, known: @telnet.KnownOption::Telnet3270Regime },
    OptionCase::{ byte: 30, known: @telnet.KnownOption::X3Pad },
    OptionCase::{ byte: 31, known: @telnet.KnownOption::Naws },
    OptionCase::{ byte: 32, known: @telnet.KnownOption::TerminalSpeed },
    OptionCase::{ byte: 33, known: @telnet.KnownOption::RemoteFlowControl },
    OptionCase::{ byte: 34, known: @telnet.KnownOption::Linemode },
    OptionCase::{ byte: 35, known: @telnet.KnownOption::XDisplayLocation },
    OptionCase::{ byte: 36, known: @telnet.KnownOption::Environment },
    OptionCase::{ byte: 37, known: @telnet.KnownOption::Authentication },
    OptionCase::{ byte: 38, known: @telnet.KnownOption::Encryption },
    OptionCase::{ byte: 39, known: @telnet.KnownOption::NewEnvironment },
    OptionCase::{ byte: 40, known: @telnet.KnownOption::Tn3270e },
    OptionCase::{ byte: 41, known: @telnet.KnownOption::Xauth },
    OptionCase::{ byte: 42, known: @telnet.KnownOption::Charset },
    OptionCase::{ byte: 43, known: @telnet.KnownOption::TelnetRemoteSerialPort },
    OptionCase::{ byte: 44, known: @telnet.KnownOption::ComPortControl },
    OptionCase::{
      byte: 45,
      known: @telnet.KnownOption::TelnetSuppressLocalEcho,
    },
    OptionCase::{ byte: 46, known: @telnet.KnownOption::TelnetStartTls },
    OptionCase::{ byte: 47, known: @telnet.KnownOption::Kermit },
    OptionCase::{ byte: 48, known: @telnet.KnownOption::SendUrl },
    OptionCase::{ byte: 49, known: @telnet.KnownOption::ForwardX },
    OptionCase::{ byte: 255, known: @telnet.KnownOption::ExtendedOptionsList },
  ]
  cases.each(fn(case_) raise {
    assert_known_option_roundtrip(case_.byte, case_.known)
  })
}

///|
test "registry samples unmodeled public assignments stay unknown and parseable" {
  let samples = [50, 138, 139, 140]
  samples.each(fn(code) raise {
    assert_true(
      @telnet.KnownOption::from_code(opt(code)) ==
      @telnet.KnownOption::Unknown(opt(code)),
    )
    restored_gen_assert_parse([255, 253, code], [
      neg(@telnet.NegotiationVerb::Do, code),
    ])
  })
}
