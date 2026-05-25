// IANA TELNET option registry characterization. Values 0..49 and 255 are mapped
// by KnownOption today; later assigned values are preserved as Unknown until the
// public enum/catalog is intentionally extended.

///|
test "IANA characterized mapped option range remains known" {
  for n = 0; n <= 49; n = n + 1 {
    let known = @telnet.KnownOption::from_code(opt(n))
    assert_true(known != @telnet.KnownOption::Unknown(opt(n)))
    assert_true(known.to_code() == opt(n))
  }
  assert_true(
    @telnet.KnownOption::from_code(opt(255)) ==
    @telnet.KnownOption::ExtendedOptionsList,
  )
}

///|
test "IANA characterized assigned newer options remain lossless unknown until modeled" {
  // IANA currently lists TELOPT PRAGMA LOGON (138), SSPI LOGON (139), and
  // TELOPT PRAGMA HEARTBEAT (140). The core preserves them losslessly while the
  // public KnownOption enum has no semantic variants for them.
  let newer_assigned = [138, 139, 140]
  newer_assigned.each(fn(n) raise {
    assert_true(
      @telnet.KnownOption::from_code(opt(n)) ==
      @telnet.KnownOption::Unknown(opt(n)),
    )
    assert_true(@telnet.KnownOption::from_code(opt(n)).to_code() == opt(n))
    restored_gen_assert_parse([255, 251, n], [
      neg(@telnet.NegotiationVerb::Will, n),
    ])
  })
}

///|
test "IANA characterized private and unassigned samples stay lossless unknown" {
  let samples = [50, 51, 70, 93, 137, 141, 200, 254]
  samples.each(fn(n) raise {
    assert_true(
      @telnet.KnownOption::from_code(opt(n)) ==
      @telnet.KnownOption::Unknown(opt(n)),
    )
    assert_true(@telnet.KnownOption::from_code(opt(n)).to_code() == opt(n))
  })
}
