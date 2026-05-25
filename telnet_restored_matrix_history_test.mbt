// Restored matrix tests from deleted generated fixtures, rewritten to assert production behavior.

///|
fn restored_matrix_config() -> @telnet.ParserConfig {
  @telnet.ParserConfig::{
    max_data_chunk_bytes: 4096,
    max_subnegotiation_bytes: 8192,
    cr_policy: @telnet.CrPolicy::Preserve,
    data_coalescing: @telnet.DataCoalescing::CoalesceUntilCommand,
    strict_commands: true,
  }
}

///|
fn restored_matrix_assert_split(
  wire : Array[Int],
  split : Int,
  expected : Array[@telnet.Event],
) -> Unit raise {
  let config = restored_matrix_config()
  assert_true(tdd_feed_split(config, wire, split) == expected)
}

///|
test "restored matrix option code 0 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(0))
  assert_true(code.to_byte() == byte(0))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 1 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(1))
  assert_true(code.to_byte() == byte(1))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 2 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(2))
  assert_true(code.to_byte() == byte(2))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 3 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(3))
  assert_true(code.to_byte() == byte(3))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 4 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(4))
  assert_true(code.to_byte() == byte(4))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 5 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(5))
  assert_true(code.to_byte() == byte(5))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 6 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(6))
  assert_true(code.to_byte() == byte(6))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 7 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(7))
  assert_true(code.to_byte() == byte(7))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 8 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(8))
  assert_true(code.to_byte() == byte(8))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 9 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(9))
  assert_true(code.to_byte() == byte(9))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 10 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(10))
  assert_true(code.to_byte() == byte(10))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 11 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(11))
  assert_true(code.to_byte() == byte(11))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 12 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(12))
  assert_true(code.to_byte() == byte(12))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 13 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(13))
  assert_true(code.to_byte() == byte(13))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 14 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(14))
  assert_true(code.to_byte() == byte(14))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 15 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(15))
  assert_true(code.to_byte() == byte(15))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 16 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(16))
  assert_true(code.to_byte() == byte(16))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 17 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(17))
  assert_true(code.to_byte() == byte(17))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 18 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(18))
  assert_true(code.to_byte() == byte(18))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 19 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(19))
  assert_true(code.to_byte() == byte(19))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 20 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(20))
  assert_true(code.to_byte() == byte(20))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 21 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(21))
  assert_true(code.to_byte() == byte(21))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 22 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(22))
  assert_true(code.to_byte() == byte(22))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 23 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(23))
  assert_true(code.to_byte() == byte(23))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 24 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(24))
  assert_true(code.to_byte() == byte(24))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 25 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(25))
  assert_true(code.to_byte() == byte(25))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 26 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(26))
  assert_true(code.to_byte() == byte(26))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 27 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(27))
  assert_true(code.to_byte() == byte(27))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 28 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(28))
  assert_true(code.to_byte() == byte(28))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 29 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(29))
  assert_true(code.to_byte() == byte(29))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 30 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(30))
  assert_true(code.to_byte() == byte(30))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 31 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(31))
  assert_true(code.to_byte() == byte(31))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 32 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(32))
  assert_true(code.to_byte() == byte(32))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 33 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(33))
  assert_true(code.to_byte() == byte(33))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 34 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(34))
  assert_true(code.to_byte() == byte(34))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 35 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(35))
  assert_true(code.to_byte() == byte(35))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 36 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(36))
  assert_true(code.to_byte() == byte(36))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 37 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(37))
  assert_true(code.to_byte() == byte(37))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 38 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(38))
  assert_true(code.to_byte() == byte(38))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 39 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(39))
  assert_true(code.to_byte() == byte(39))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 40 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(40))
  assert_true(code.to_byte() == byte(40))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 41 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(41))
  assert_true(code.to_byte() == byte(41))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 42 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(42))
  assert_true(code.to_byte() == byte(42))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 43 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(43))
  assert_true(code.to_byte() == byte(43))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 44 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(44))
  assert_true(code.to_byte() == byte(44))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 45 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(45))
  assert_true(code.to_byte() == byte(45))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 46 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(46))
  assert_true(code.to_byte() == byte(46))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 47 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(47))
  assert_true(code.to_byte() == byte(47))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 48 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(48))
  assert_true(code.to_byte() == byte(48))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 49 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(49))
  assert_true(code.to_byte() == byte(49))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 50 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(50))
  assert_true(code.to_byte() == byte(50))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 51 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(51))
  assert_true(code.to_byte() == byte(51))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 52 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(52))
  assert_true(code.to_byte() == byte(52))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 53 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(53))
  assert_true(code.to_byte() == byte(53))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 54 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(54))
  assert_true(code.to_byte() == byte(54))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 55 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(55))
  assert_true(code.to_byte() == byte(55))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 56 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(56))
  assert_true(code.to_byte() == byte(56))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 57 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(57))
  assert_true(code.to_byte() == byte(57))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 58 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(58))
  assert_true(code.to_byte() == byte(58))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 59 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(59))
  assert_true(code.to_byte() == byte(59))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 60 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(60))
  assert_true(code.to_byte() == byte(60))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 61 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(61))
  assert_true(code.to_byte() == byte(61))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 62 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(62))
  assert_true(code.to_byte() == byte(62))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 63 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(63))
  assert_true(code.to_byte() == byte(63))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 64 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(64))
  assert_true(code.to_byte() == byte(64))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 65 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(65))
  assert_true(code.to_byte() == byte(65))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 66 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(66))
  assert_true(code.to_byte() == byte(66))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 67 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(67))
  assert_true(code.to_byte() == byte(67))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 68 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(68))
  assert_true(code.to_byte() == byte(68))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 69 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(69))
  assert_true(code.to_byte() == byte(69))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 70 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(70))
  assert_true(code.to_byte() == byte(70))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 71 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(71))
  assert_true(code.to_byte() == byte(71))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 72 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(72))
  assert_true(code.to_byte() == byte(72))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 73 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(73))
  assert_true(code.to_byte() == byte(73))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 74 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(74))
  assert_true(code.to_byte() == byte(74))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 75 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(75))
  assert_true(code.to_byte() == byte(75))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 76 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(76))
  assert_true(code.to_byte() == byte(76))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 77 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(77))
  assert_true(code.to_byte() == byte(77))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 78 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(78))
  assert_true(code.to_byte() == byte(78))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 79 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(79))
  assert_true(code.to_byte() == byte(79))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 80 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(80))
  assert_true(code.to_byte() == byte(80))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 81 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(81))
  assert_true(code.to_byte() == byte(81))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 82 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(82))
  assert_true(code.to_byte() == byte(82))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 83 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(83))
  assert_true(code.to_byte() == byte(83))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 84 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(84))
  assert_true(code.to_byte() == byte(84))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 85 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(85))
  assert_true(code.to_byte() == byte(85))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 86 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(86))
  assert_true(code.to_byte() == byte(86))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 87 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(87))
  assert_true(code.to_byte() == byte(87))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 88 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(88))
  assert_true(code.to_byte() == byte(88))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 89 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(89))
  assert_true(code.to_byte() == byte(89))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 90 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(90))
  assert_true(code.to_byte() == byte(90))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 91 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(91))
  assert_true(code.to_byte() == byte(91))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 92 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(92))
  assert_true(code.to_byte() == byte(92))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 93 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(93))
  assert_true(code.to_byte() == byte(93))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 94 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(94))
  assert_true(code.to_byte() == byte(94))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 95 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(95))
  assert_true(code.to_byte() == byte(95))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 96 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(96))
  assert_true(code.to_byte() == byte(96))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 97 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(97))
  assert_true(code.to_byte() == byte(97))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 98 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(98))
  assert_true(code.to_byte() == byte(98))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 99 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(99))
  assert_true(code.to_byte() == byte(99))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 100 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(100))
  assert_true(code.to_byte() == byte(100))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 101 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(101))
  assert_true(code.to_byte() == byte(101))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 102 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(102))
  assert_true(code.to_byte() == byte(102))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 103 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(103))
  assert_true(code.to_byte() == byte(103))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 104 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(104))
  assert_true(code.to_byte() == byte(104))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 105 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(105))
  assert_true(code.to_byte() == byte(105))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 106 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(106))
  assert_true(code.to_byte() == byte(106))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 107 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(107))
  assert_true(code.to_byte() == byte(107))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 108 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(108))
  assert_true(code.to_byte() == byte(108))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 109 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(109))
  assert_true(code.to_byte() == byte(109))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 110 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(110))
  assert_true(code.to_byte() == byte(110))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 111 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(111))
  assert_true(code.to_byte() == byte(111))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 112 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(112))
  assert_true(code.to_byte() == byte(112))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 113 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(113))
  assert_true(code.to_byte() == byte(113))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 114 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(114))
  assert_true(code.to_byte() == byte(114))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 115 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(115))
  assert_true(code.to_byte() == byte(115))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 116 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(116))
  assert_true(code.to_byte() == byte(116))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 117 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(117))
  assert_true(code.to_byte() == byte(117))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 118 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(118))
  assert_true(code.to_byte() == byte(118))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 119 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(119))
  assert_true(code.to_byte() == byte(119))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 120 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(120))
  assert_true(code.to_byte() == byte(120))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 121 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(121))
  assert_true(code.to_byte() == byte(121))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 122 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(122))
  assert_true(code.to_byte() == byte(122))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 123 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(123))
  assert_true(code.to_byte() == byte(123))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 124 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(124))
  assert_true(code.to_byte() == byte(124))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 125 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(125))
  assert_true(code.to_byte() == byte(125))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 126 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(126))
  assert_true(code.to_byte() == byte(126))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 127 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(127))
  assert_true(code.to_byte() == byte(127))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 128 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(128))
  assert_true(code.to_byte() == byte(128))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 129 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(129))
  assert_true(code.to_byte() == byte(129))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 130 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(130))
  assert_true(code.to_byte() == byte(130))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 131 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(131))
  assert_true(code.to_byte() == byte(131))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 132 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(132))
  assert_true(code.to_byte() == byte(132))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 133 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(133))
  assert_true(code.to_byte() == byte(133))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 134 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(134))
  assert_true(code.to_byte() == byte(134))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 135 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(135))
  assert_true(code.to_byte() == byte(135))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 136 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(136))
  assert_true(code.to_byte() == byte(136))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 137 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(137))
  assert_true(code.to_byte() == byte(137))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 138 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(138))
  assert_true(code.to_byte() == byte(138))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 139 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(139))
  assert_true(code.to_byte() == byte(139))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 140 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(140))
  assert_true(code.to_byte() == byte(140))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 141 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(141))
  assert_true(code.to_byte() == byte(141))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 142 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(142))
  assert_true(code.to_byte() == byte(142))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 143 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(143))
  assert_true(code.to_byte() == byte(143))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 144 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(144))
  assert_true(code.to_byte() == byte(144))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 145 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(145))
  assert_true(code.to_byte() == byte(145))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 146 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(146))
  assert_true(code.to_byte() == byte(146))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 147 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(147))
  assert_true(code.to_byte() == byte(147))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 148 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(148))
  assert_true(code.to_byte() == byte(148))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 149 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(149))
  assert_true(code.to_byte() == byte(149))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 150 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(150))
  assert_true(code.to_byte() == byte(150))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 151 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(151))
  assert_true(code.to_byte() == byte(151))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 152 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(152))
  assert_true(code.to_byte() == byte(152))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 153 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(153))
  assert_true(code.to_byte() == byte(153))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 154 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(154))
  assert_true(code.to_byte() == byte(154))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 155 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(155))
  assert_true(code.to_byte() == byte(155))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 156 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(156))
  assert_true(code.to_byte() == byte(156))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 157 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(157))
  assert_true(code.to_byte() == byte(157))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 158 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(158))
  assert_true(code.to_byte() == byte(158))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 159 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(159))
  assert_true(code.to_byte() == byte(159))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 160 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(160))
  assert_true(code.to_byte() == byte(160))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 161 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(161))
  assert_true(code.to_byte() == byte(161))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 162 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(162))
  assert_true(code.to_byte() == byte(162))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 163 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(163))
  assert_true(code.to_byte() == byte(163))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 164 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(164))
  assert_true(code.to_byte() == byte(164))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 165 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(165))
  assert_true(code.to_byte() == byte(165))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 166 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(166))
  assert_true(code.to_byte() == byte(166))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 167 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(167))
  assert_true(code.to_byte() == byte(167))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 168 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(168))
  assert_true(code.to_byte() == byte(168))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 169 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(169))
  assert_true(code.to_byte() == byte(169))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 170 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(170))
  assert_true(code.to_byte() == byte(170))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 171 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(171))
  assert_true(code.to_byte() == byte(171))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 172 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(172))
  assert_true(code.to_byte() == byte(172))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 173 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(173))
  assert_true(code.to_byte() == byte(173))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 174 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(174))
  assert_true(code.to_byte() == byte(174))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 175 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(175))
  assert_true(code.to_byte() == byte(175))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 176 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(176))
  assert_true(code.to_byte() == byte(176))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 177 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(177))
  assert_true(code.to_byte() == byte(177))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 178 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(178))
  assert_true(code.to_byte() == byte(178))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 179 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(179))
  assert_true(code.to_byte() == byte(179))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 180 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(180))
  assert_true(code.to_byte() == byte(180))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 181 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(181))
  assert_true(code.to_byte() == byte(181))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 182 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(182))
  assert_true(code.to_byte() == byte(182))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 183 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(183))
  assert_true(code.to_byte() == byte(183))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 184 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(184))
  assert_true(code.to_byte() == byte(184))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 185 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(185))
  assert_true(code.to_byte() == byte(185))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 186 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(186))
  assert_true(code.to_byte() == byte(186))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 187 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(187))
  assert_true(code.to_byte() == byte(187))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 188 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(188))
  assert_true(code.to_byte() == byte(188))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 189 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(189))
  assert_true(code.to_byte() == byte(189))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 190 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(190))
  assert_true(code.to_byte() == byte(190))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 191 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(191))
  assert_true(code.to_byte() == byte(191))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 192 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(192))
  assert_true(code.to_byte() == byte(192))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 193 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(193))
  assert_true(code.to_byte() == byte(193))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 194 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(194))
  assert_true(code.to_byte() == byte(194))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 195 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(195))
  assert_true(code.to_byte() == byte(195))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 196 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(196))
  assert_true(code.to_byte() == byte(196))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 197 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(197))
  assert_true(code.to_byte() == byte(197))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 198 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(198))
  assert_true(code.to_byte() == byte(198))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 199 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(199))
  assert_true(code.to_byte() == byte(199))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 200 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(200))
  assert_true(code.to_byte() == byte(200))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 201 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(201))
  assert_true(code.to_byte() == byte(201))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 202 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(202))
  assert_true(code.to_byte() == byte(202))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 203 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(203))
  assert_true(code.to_byte() == byte(203))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 204 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(204))
  assert_true(code.to_byte() == byte(204))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 205 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(205))
  assert_true(code.to_byte() == byte(205))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 206 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(206))
  assert_true(code.to_byte() == byte(206))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 207 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(207))
  assert_true(code.to_byte() == byte(207))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 208 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(208))
  assert_true(code.to_byte() == byte(208))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 209 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(209))
  assert_true(code.to_byte() == byte(209))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 210 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(210))
  assert_true(code.to_byte() == byte(210))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 211 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(211))
  assert_true(code.to_byte() == byte(211))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 212 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(212))
  assert_true(code.to_byte() == byte(212))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 213 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(213))
  assert_true(code.to_byte() == byte(213))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 214 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(214))
  assert_true(code.to_byte() == byte(214))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 215 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(215))
  assert_true(code.to_byte() == byte(215))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 216 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(216))
  assert_true(code.to_byte() == byte(216))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 217 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(217))
  assert_true(code.to_byte() == byte(217))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 218 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(218))
  assert_true(code.to_byte() == byte(218))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 219 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(219))
  assert_true(code.to_byte() == byte(219))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 220 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(220))
  assert_true(code.to_byte() == byte(220))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 221 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(221))
  assert_true(code.to_byte() == byte(221))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 222 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(222))
  assert_true(code.to_byte() == byte(222))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 223 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(223))
  assert_true(code.to_byte() == byte(223))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 224 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(224))
  assert_true(code.to_byte() == byte(224))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 225 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(225))
  assert_true(code.to_byte() == byte(225))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 226 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(226))
  assert_true(code.to_byte() == byte(226))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 227 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(227))
  assert_true(code.to_byte() == byte(227))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 228 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(228))
  assert_true(code.to_byte() == byte(228))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 229 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(229))
  assert_true(code.to_byte() == byte(229))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 230 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(230))
  assert_true(code.to_byte() == byte(230))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 231 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(231))
  assert_true(code.to_byte() == byte(231))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 232 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(232))
  assert_true(code.to_byte() == byte(232))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 233 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(233))
  assert_true(code.to_byte() == byte(233))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 234 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(234))
  assert_true(code.to_byte() == byte(234))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 235 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(235))
  assert_true(code.to_byte() == byte(235))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 236 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(236))
  assert_true(code.to_byte() == byte(236))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 237 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(237))
  assert_true(code.to_byte() == byte(237))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 238 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(238))
  assert_true(code.to_byte() == byte(238))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 239 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(239))
  assert_true(code.to_byte() == byte(239))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 240 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(240))
  assert_true(code.to_byte() == byte(240))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 241 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(241))
  assert_true(code.to_byte() == byte(241))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 242 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(242))
  assert_true(code.to_byte() == byte(242))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 243 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(243))
  assert_true(code.to_byte() == byte(243))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 244 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(244))
  assert_true(code.to_byte() == byte(244))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 245 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(245))
  assert_true(code.to_byte() == byte(245))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 246 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(246))
  assert_true(code.to_byte() == byte(246))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 247 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(247))
  assert_true(code.to_byte() == byte(247))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 248 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(248))
  assert_true(code.to_byte() == byte(248))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 249 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(249))
  assert_true(code.to_byte() == byte(249))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 250 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(250))
  assert_true(code.to_byte() == byte(250))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 251 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(251))
  assert_true(code.to_byte() == byte(251))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 252 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(252))
  assert_true(code.to_byte() == byte(252))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 253 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(253))
  assert_true(code.to_byte() == byte(253))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 254 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(254))
  assert_true(code.to_byte() == byte(254))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix option code 255 is lossless through APIs" {
  let code = @telnet.OptionCode::new(byte(255))
  assert_true(code.to_byte() == byte(255))
  assert_true(@telnet.KnownOption::from_code(code).to_code() == code)
}

///|
test "restored matrix strict invalid IAC byte 0 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 0]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(0))],
  )
  assert_true(@telnet.Command::from_byte(byte(0)) == None)
}

///|
test "restored matrix strict invalid IAC byte 1 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 1]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(1))],
  )
  assert_true(@telnet.Command::from_byte(byte(1)) == None)
}

///|
test "restored matrix strict invalid IAC byte 2 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 2]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(2))],
  )
  assert_true(@telnet.Command::from_byte(byte(2)) == None)
}

///|
test "restored matrix strict invalid IAC byte 3 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 3]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(3))],
  )
  assert_true(@telnet.Command::from_byte(byte(3)) == None)
}

///|
test "restored matrix strict invalid IAC byte 4 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 4]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(4))],
  )
  assert_true(@telnet.Command::from_byte(byte(4)) == None)
}

///|
test "restored matrix strict invalid IAC byte 5 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 5]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(5))],
  )
  assert_true(@telnet.Command::from_byte(byte(5)) == None)
}

///|
test "restored matrix strict invalid IAC byte 6 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 6]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(6))],
  )
  assert_true(@telnet.Command::from_byte(byte(6)) == None)
}

///|
test "restored matrix strict invalid IAC byte 7 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 7]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(7))],
  )
  assert_true(@telnet.Command::from_byte(byte(7)) == None)
}

///|
test "restored matrix strict invalid IAC byte 8 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 8]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(8))],
  )
  assert_true(@telnet.Command::from_byte(byte(8)) == None)
}

///|
test "restored matrix strict invalid IAC byte 9 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 9]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(9))],
  )
  assert_true(@telnet.Command::from_byte(byte(9)) == None)
}

///|
test "restored matrix strict invalid IAC byte 10 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 10]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(10))],
  )
  assert_true(@telnet.Command::from_byte(byte(10)) == None)
}

///|
test "restored matrix strict invalid IAC byte 11 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 11]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(11))],
  )
  assert_true(@telnet.Command::from_byte(byte(11)) == None)
}

///|
test "restored matrix strict invalid IAC byte 12 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 12]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(12))],
  )
  assert_true(@telnet.Command::from_byte(byte(12)) == None)
}

///|
test "restored matrix strict invalid IAC byte 13 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 13]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(13))],
  )
  assert_true(@telnet.Command::from_byte(byte(13)) == None)
}

///|
test "restored matrix strict invalid IAC byte 14 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 14]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(14))],
  )
  assert_true(@telnet.Command::from_byte(byte(14)) == None)
}

///|
test "restored matrix strict invalid IAC byte 15 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 15]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(15))],
  )
  assert_true(@telnet.Command::from_byte(byte(15)) == None)
}

///|
test "restored matrix strict invalid IAC byte 16 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 16]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(16))],
  )
  assert_true(@telnet.Command::from_byte(byte(16)) == None)
}

///|
test "restored matrix strict invalid IAC byte 17 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 17]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(17))],
  )
  assert_true(@telnet.Command::from_byte(byte(17)) == None)
}

///|
test "restored matrix strict invalid IAC byte 18 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 18]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(18))],
  )
  assert_true(@telnet.Command::from_byte(byte(18)) == None)
}

///|
test "restored matrix strict invalid IAC byte 19 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 19]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(19))],
  )
  assert_true(@telnet.Command::from_byte(byte(19)) == None)
}

///|
test "restored matrix strict invalid IAC byte 20 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 20]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(20))],
  )
  assert_true(@telnet.Command::from_byte(byte(20)) == None)
}

///|
test "restored matrix strict invalid IAC byte 21 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 21]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(21))],
  )
  assert_true(@telnet.Command::from_byte(byte(21)) == None)
}

///|
test "restored matrix strict invalid IAC byte 22 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 22]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(22))],
  )
  assert_true(@telnet.Command::from_byte(byte(22)) == None)
}

///|
test "restored matrix strict invalid IAC byte 23 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 23]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(23))],
  )
  assert_true(@telnet.Command::from_byte(byte(23)) == None)
}

///|
test "restored matrix strict invalid IAC byte 24 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 24]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(24))],
  )
  assert_true(@telnet.Command::from_byte(byte(24)) == None)
}

///|
test "restored matrix strict invalid IAC byte 25 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 25]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(25))],
  )
  assert_true(@telnet.Command::from_byte(byte(25)) == None)
}

///|
test "restored matrix strict invalid IAC byte 26 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 26]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(26))],
  )
  assert_true(@telnet.Command::from_byte(byte(26)) == None)
}

///|
test "restored matrix strict invalid IAC byte 27 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 27]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(27))],
  )
  assert_true(@telnet.Command::from_byte(byte(27)) == None)
}

///|
test "restored matrix strict invalid IAC byte 28 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 28]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(28))],
  )
  assert_true(@telnet.Command::from_byte(byte(28)) == None)
}

///|
test "restored matrix strict invalid IAC byte 29 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 29]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(29))],
  )
  assert_true(@telnet.Command::from_byte(byte(29)) == None)
}

///|
test "restored matrix strict invalid IAC byte 30 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 30]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(30))],
  )
  assert_true(@telnet.Command::from_byte(byte(30)) == None)
}

///|
test "restored matrix strict invalid IAC byte 31 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 31]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(31))],
  )
  assert_true(@telnet.Command::from_byte(byte(31)) == None)
}

///|
test "restored matrix strict invalid IAC byte 32 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 32]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(32))],
  )
  assert_true(@telnet.Command::from_byte(byte(32)) == None)
}

///|
test "restored matrix strict invalid IAC byte 33 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 33]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(33))],
  )
  assert_true(@telnet.Command::from_byte(byte(33)) == None)
}

///|
test "restored matrix strict invalid IAC byte 34 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 34]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(34))],
  )
  assert_true(@telnet.Command::from_byte(byte(34)) == None)
}

///|
test "restored matrix strict invalid IAC byte 35 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 35]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(35))],
  )
  assert_true(@telnet.Command::from_byte(byte(35)) == None)
}

///|
test "restored matrix strict invalid IAC byte 36 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 36]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(36))],
  )
  assert_true(@telnet.Command::from_byte(byte(36)) == None)
}

///|
test "restored matrix strict invalid IAC byte 37 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 37]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(37))],
  )
  assert_true(@telnet.Command::from_byte(byte(37)) == None)
}

///|
test "restored matrix strict invalid IAC byte 38 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 38]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(38))],
  )
  assert_true(@telnet.Command::from_byte(byte(38)) == None)
}

///|
test "restored matrix strict invalid IAC byte 39 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 39]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(39))],
  )
  assert_true(@telnet.Command::from_byte(byte(39)) == None)
}

///|
test "restored matrix strict invalid IAC byte 40 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 40]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(40))],
  )
  assert_true(@telnet.Command::from_byte(byte(40)) == None)
}

///|
test "restored matrix strict invalid IAC byte 41 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 41]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(41))],
  )
  assert_true(@telnet.Command::from_byte(byte(41)) == None)
}

///|
test "restored matrix strict invalid IAC byte 42 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 42]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(42))],
  )
  assert_true(@telnet.Command::from_byte(byte(42)) == None)
}

///|
test "restored matrix strict invalid IAC byte 43 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 43]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(43))],
  )
  assert_true(@telnet.Command::from_byte(byte(43)) == None)
}

///|
test "restored matrix strict invalid IAC byte 44 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 44]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(44))],
  )
  assert_true(@telnet.Command::from_byte(byte(44)) == None)
}

///|
test "restored matrix strict invalid IAC byte 45 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 45]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(45))],
  )
  assert_true(@telnet.Command::from_byte(byte(45)) == None)
}

///|
test "restored matrix strict invalid IAC byte 46 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 46]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(46))],
  )
  assert_true(@telnet.Command::from_byte(byte(46)) == None)
}

///|
test "restored matrix strict invalid IAC byte 47 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 47]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(47))],
  )
  assert_true(@telnet.Command::from_byte(byte(47)) == None)
}

///|
test "restored matrix strict invalid IAC byte 48 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 48]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(48))],
  )
  assert_true(@telnet.Command::from_byte(byte(48)) == None)
}

///|
test "restored matrix strict invalid IAC byte 49 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 49]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(49))],
  )
  assert_true(@telnet.Command::from_byte(byte(49)) == None)
}

///|
test "restored matrix strict invalid IAC byte 50 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 50]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(50))],
  )
  assert_true(@telnet.Command::from_byte(byte(50)) == None)
}

///|
test "restored matrix strict invalid IAC byte 51 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 51]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(51))],
  )
  assert_true(@telnet.Command::from_byte(byte(51)) == None)
}

///|
test "restored matrix strict invalid IAC byte 52 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 52]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(52))],
  )
  assert_true(@telnet.Command::from_byte(byte(52)) == None)
}

///|
test "restored matrix strict invalid IAC byte 53 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 53]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(53))],
  )
  assert_true(@telnet.Command::from_byte(byte(53)) == None)
}

///|
test "restored matrix strict invalid IAC byte 54 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 54]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(54))],
  )
  assert_true(@telnet.Command::from_byte(byte(54)) == None)
}

///|
test "restored matrix strict invalid IAC byte 55 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 55]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(55))],
  )
  assert_true(@telnet.Command::from_byte(byte(55)) == None)
}

///|
test "restored matrix strict invalid IAC byte 56 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 56]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(56))],
  )
  assert_true(@telnet.Command::from_byte(byte(56)) == None)
}

///|
test "restored matrix strict invalid IAC byte 57 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 57]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(57))],
  )
  assert_true(@telnet.Command::from_byte(byte(57)) == None)
}

///|
test "restored matrix strict invalid IAC byte 58 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 58]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(58))],
  )
  assert_true(@telnet.Command::from_byte(byte(58)) == None)
}

///|
test "restored matrix strict invalid IAC byte 59 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 59]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(59))],
  )
  assert_true(@telnet.Command::from_byte(byte(59)) == None)
}

///|
test "restored matrix strict invalid IAC byte 60 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 60]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(60))],
  )
  assert_true(@telnet.Command::from_byte(byte(60)) == None)
}

///|
test "restored matrix strict invalid IAC byte 61 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 61]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(61))],
  )
  assert_true(@telnet.Command::from_byte(byte(61)) == None)
}

///|
test "restored matrix strict invalid IAC byte 62 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 62]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(62))],
  )
  assert_true(@telnet.Command::from_byte(byte(62)) == None)
}

///|
test "restored matrix strict invalid IAC byte 63 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 63]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(63))],
  )
  assert_true(@telnet.Command::from_byte(byte(63)) == None)
}

///|
test "restored matrix strict invalid IAC byte 64 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 64]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(64))],
  )
  assert_true(@telnet.Command::from_byte(byte(64)) == None)
}

///|
test "restored matrix strict invalid IAC byte 65 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 65]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(65))],
  )
  assert_true(@telnet.Command::from_byte(byte(65)) == None)
}

///|
test "restored matrix strict invalid IAC byte 66 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 66]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(66))],
  )
  assert_true(@telnet.Command::from_byte(byte(66)) == None)
}

///|
test "restored matrix strict invalid IAC byte 67 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 67]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(67))],
  )
  assert_true(@telnet.Command::from_byte(byte(67)) == None)
}

///|
test "restored matrix strict invalid IAC byte 68 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 68]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(68))],
  )
  assert_true(@telnet.Command::from_byte(byte(68)) == None)
}

///|
test "restored matrix strict invalid IAC byte 69 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 69]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(69))],
  )
  assert_true(@telnet.Command::from_byte(byte(69)) == None)
}

///|
test "restored matrix strict invalid IAC byte 70 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 70]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(70))],
  )
  assert_true(@telnet.Command::from_byte(byte(70)) == None)
}

///|
test "restored matrix strict invalid IAC byte 71 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 71]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(71))],
  )
  assert_true(@telnet.Command::from_byte(byte(71)) == None)
}

///|
test "restored matrix strict invalid IAC byte 72 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 72]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(72))],
  )
  assert_true(@telnet.Command::from_byte(byte(72)) == None)
}

///|
test "restored matrix strict invalid IAC byte 73 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 73]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(73))],
  )
  assert_true(@telnet.Command::from_byte(byte(73)) == None)
}

///|
test "restored matrix strict invalid IAC byte 74 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 74]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(74))],
  )
  assert_true(@telnet.Command::from_byte(byte(74)) == None)
}

///|
test "restored matrix strict invalid IAC byte 75 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 75]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(75))],
  )
  assert_true(@telnet.Command::from_byte(byte(75)) == None)
}

///|
test "restored matrix strict invalid IAC byte 76 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 76]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(76))],
  )
  assert_true(@telnet.Command::from_byte(byte(76)) == None)
}

///|
test "restored matrix strict invalid IAC byte 77 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 77]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(77))],
  )
  assert_true(@telnet.Command::from_byte(byte(77)) == None)
}

///|
test "restored matrix strict invalid IAC byte 78 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 78]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(78))],
  )
  assert_true(@telnet.Command::from_byte(byte(78)) == None)
}

///|
test "restored matrix strict invalid IAC byte 79 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 79]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(79))],
  )
  assert_true(@telnet.Command::from_byte(byte(79)) == None)
}

///|
test "restored matrix strict invalid IAC byte 80 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 80]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(80))],
  )
  assert_true(@telnet.Command::from_byte(byte(80)) == None)
}

///|
test "restored matrix strict invalid IAC byte 81 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 81]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(81))],
  )
  assert_true(@telnet.Command::from_byte(byte(81)) == None)
}

///|
test "restored matrix strict invalid IAC byte 82 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 82]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(82))],
  )
  assert_true(@telnet.Command::from_byte(byte(82)) == None)
}

///|
test "restored matrix strict invalid IAC byte 83 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 83]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(83))],
  )
  assert_true(@telnet.Command::from_byte(byte(83)) == None)
}

///|
test "restored matrix strict invalid IAC byte 84 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 84]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(84))],
  )
  assert_true(@telnet.Command::from_byte(byte(84)) == None)
}

///|
test "restored matrix strict invalid IAC byte 85 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 85]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(85))],
  )
  assert_true(@telnet.Command::from_byte(byte(85)) == None)
}

///|
test "restored matrix strict invalid IAC byte 86 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 86]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(86))],
  )
  assert_true(@telnet.Command::from_byte(byte(86)) == None)
}

///|
test "restored matrix strict invalid IAC byte 87 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 87]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(87))],
  )
  assert_true(@telnet.Command::from_byte(byte(87)) == None)
}

///|
test "restored matrix strict invalid IAC byte 88 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 88]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(88))],
  )
  assert_true(@telnet.Command::from_byte(byte(88)) == None)
}

///|
test "restored matrix strict invalid IAC byte 89 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 89]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(89))],
  )
  assert_true(@telnet.Command::from_byte(byte(89)) == None)
}

///|
test "restored matrix strict invalid IAC byte 90 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 90]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(90))],
  )
  assert_true(@telnet.Command::from_byte(byte(90)) == None)
}

///|
test "restored matrix strict invalid IAC byte 91 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 91]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(91))],
  )
  assert_true(@telnet.Command::from_byte(byte(91)) == None)
}

///|
test "restored matrix strict invalid IAC byte 92 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 92]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(92))],
  )
  assert_true(@telnet.Command::from_byte(byte(92)) == None)
}

///|
test "restored matrix strict invalid IAC byte 93 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 93]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(93))],
  )
  assert_true(@telnet.Command::from_byte(byte(93)) == None)
}

///|
test "restored matrix strict invalid IAC byte 94 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 94]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(94))],
  )
  assert_true(@telnet.Command::from_byte(byte(94)) == None)
}

///|
test "restored matrix strict invalid IAC byte 95 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 95]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(95))],
  )
  assert_true(@telnet.Command::from_byte(byte(95)) == None)
}

///|
test "restored matrix strict invalid IAC byte 96 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 96]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(96))],
  )
  assert_true(@telnet.Command::from_byte(byte(96)) == None)
}

///|
test "restored matrix strict invalid IAC byte 97 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 97]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(97))],
  )
  assert_true(@telnet.Command::from_byte(byte(97)) == None)
}

///|
test "restored matrix strict invalid IAC byte 98 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 98]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(98))],
  )
  assert_true(@telnet.Command::from_byte(byte(98)) == None)
}

///|
test "restored matrix strict invalid IAC byte 99 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 99]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(99))],
  )
  assert_true(@telnet.Command::from_byte(byte(99)) == None)
}

///|
test "restored matrix strict invalid IAC byte 100 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 100]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(100))],
  )
  assert_true(@telnet.Command::from_byte(byte(100)) == None)
}

///|
test "restored matrix strict invalid IAC byte 101 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 101]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(101))],
  )
  assert_true(@telnet.Command::from_byte(byte(101)) == None)
}

///|
test "restored matrix strict invalid IAC byte 102 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 102]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(102))],
  )
  assert_true(@telnet.Command::from_byte(byte(102)) == None)
}

///|
test "restored matrix strict invalid IAC byte 103 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 103]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(103))],
  )
  assert_true(@telnet.Command::from_byte(byte(103)) == None)
}

///|
test "restored matrix strict invalid IAC byte 104 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 104]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(104))],
  )
  assert_true(@telnet.Command::from_byte(byte(104)) == None)
}

///|
test "restored matrix strict invalid IAC byte 105 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 105]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(105))],
  )
  assert_true(@telnet.Command::from_byte(byte(105)) == None)
}

///|
test "restored matrix strict invalid IAC byte 106 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 106]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(106))],
  )
  assert_true(@telnet.Command::from_byte(byte(106)) == None)
}

///|
test "restored matrix strict invalid IAC byte 107 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 107]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(107))],
  )
  assert_true(@telnet.Command::from_byte(byte(107)) == None)
}

///|
test "restored matrix strict invalid IAC byte 108 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 108]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(108))],
  )
  assert_true(@telnet.Command::from_byte(byte(108)) == None)
}

///|
test "restored matrix strict invalid IAC byte 109 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 109]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(109))],
  )
  assert_true(@telnet.Command::from_byte(byte(109)) == None)
}

///|
test "restored matrix strict invalid IAC byte 110 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 110]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(110))],
  )
  assert_true(@telnet.Command::from_byte(byte(110)) == None)
}

///|
test "restored matrix strict invalid IAC byte 111 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 111]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(111))],
  )
  assert_true(@telnet.Command::from_byte(byte(111)) == None)
}

///|
test "restored matrix strict invalid IAC byte 112 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 112]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(112))],
  )
  assert_true(@telnet.Command::from_byte(byte(112)) == None)
}

///|
test "restored matrix strict invalid IAC byte 113 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 113]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(113))],
  )
  assert_true(@telnet.Command::from_byte(byte(113)) == None)
}

///|
test "restored matrix strict invalid IAC byte 114 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 114]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(114))],
  )
  assert_true(@telnet.Command::from_byte(byte(114)) == None)
}

///|
test "restored matrix strict invalid IAC byte 115 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 115]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(115))],
  )
  assert_true(@telnet.Command::from_byte(byte(115)) == None)
}

///|
test "restored matrix strict invalid IAC byte 116 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 116]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(116))],
  )
  assert_true(@telnet.Command::from_byte(byte(116)) == None)
}

///|
test "restored matrix strict invalid IAC byte 117 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 117]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(117))],
  )
  assert_true(@telnet.Command::from_byte(byte(117)) == None)
}

///|
test "restored matrix strict invalid IAC byte 118 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 118]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(118))],
  )
  assert_true(@telnet.Command::from_byte(byte(118)) == None)
}

///|
test "restored matrix strict invalid IAC byte 119 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 119]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(119))],
  )
  assert_true(@telnet.Command::from_byte(byte(119)) == None)
}

///|
test "restored matrix strict invalid IAC byte 120 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 120]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(120))],
  )
  assert_true(@telnet.Command::from_byte(byte(120)) == None)
}

///|
test "restored matrix strict invalid IAC byte 121 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 121]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(121))],
  )
  assert_true(@telnet.Command::from_byte(byte(121)) == None)
}

///|
test "restored matrix strict invalid IAC byte 122 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 122]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(122))],
  )
  assert_true(@telnet.Command::from_byte(byte(122)) == None)
}

///|
test "restored matrix strict invalid IAC byte 123 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 123]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(123))],
  )
  assert_true(@telnet.Command::from_byte(byte(123)) == None)
}

///|
test "restored matrix strict invalid IAC byte 124 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 124]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(124))],
  )
  assert_true(@telnet.Command::from_byte(byte(124)) == None)
}

///|
test "restored matrix strict invalid IAC byte 125 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 125]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(125))],
  )
  assert_true(@telnet.Command::from_byte(byte(125)) == None)
}

///|
test "restored matrix strict invalid IAC byte 126 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 126]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(126))],
  )
  assert_true(@telnet.Command::from_byte(byte(126)) == None)
}

///|
test "restored matrix strict invalid IAC byte 127 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 127]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(127))],
  )
  assert_true(@telnet.Command::from_byte(byte(127)) == None)
}

///|
test "restored matrix strict invalid IAC byte 128 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 128]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(128))],
  )
  assert_true(@telnet.Command::from_byte(byte(128)) == None)
}

///|
test "restored matrix strict invalid IAC byte 129 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 129]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(129))],
  )
  assert_true(@telnet.Command::from_byte(byte(129)) == None)
}

///|
test "restored matrix strict invalid IAC byte 130 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 130]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(130))],
  )
  assert_true(@telnet.Command::from_byte(byte(130)) == None)
}

///|
test "restored matrix strict invalid IAC byte 131 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 131]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(131))],
  )
  assert_true(@telnet.Command::from_byte(byte(131)) == None)
}

///|
test "restored matrix strict invalid IAC byte 132 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 132]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(132))],
  )
  assert_true(@telnet.Command::from_byte(byte(132)) == None)
}

///|
test "restored matrix strict invalid IAC byte 133 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 133]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(133))],
  )
  assert_true(@telnet.Command::from_byte(byte(133)) == None)
}

///|
test "restored matrix strict invalid IAC byte 134 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 134]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(134))],
  )
  assert_true(@telnet.Command::from_byte(byte(134)) == None)
}

///|
test "restored matrix strict invalid IAC byte 135 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 135]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(135))],
  )
  assert_true(@telnet.Command::from_byte(byte(135)) == None)
}

///|
test "restored matrix strict invalid IAC byte 136 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 136]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(136))],
  )
  assert_true(@telnet.Command::from_byte(byte(136)) == None)
}

///|
test "restored matrix strict invalid IAC byte 137 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 137]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(137))],
  )
  assert_true(@telnet.Command::from_byte(byte(137)) == None)
}

///|
test "restored matrix strict invalid IAC byte 138 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 138]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(138))],
  )
  assert_true(@telnet.Command::from_byte(byte(138)) == None)
}

///|
test "restored matrix strict invalid IAC byte 139 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 139]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(139))],
  )
  assert_true(@telnet.Command::from_byte(byte(139)) == None)
}

///|
test "restored matrix strict invalid IAC byte 140 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 140]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(140))],
  )
  assert_true(@telnet.Command::from_byte(byte(140)) == None)
}

///|
test "restored matrix strict invalid IAC byte 141 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 141]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(141))],
  )
  assert_true(@telnet.Command::from_byte(byte(141)) == None)
}

///|
test "restored matrix strict invalid IAC byte 142 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 142]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(142))],
  )
  assert_true(@telnet.Command::from_byte(byte(142)) == None)
}

///|
test "restored matrix strict invalid IAC byte 143 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 143]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(143))],
  )
  assert_true(@telnet.Command::from_byte(byte(143)) == None)
}

///|
test "restored matrix strict invalid IAC byte 144 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 144]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(144))],
  )
  assert_true(@telnet.Command::from_byte(byte(144)) == None)
}

///|
test "restored matrix strict invalid IAC byte 145 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 145]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(145))],
  )
  assert_true(@telnet.Command::from_byte(byte(145)) == None)
}

///|
test "restored matrix strict invalid IAC byte 146 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 146]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(146))],
  )
  assert_true(@telnet.Command::from_byte(byte(146)) == None)
}

///|
test "restored matrix strict invalid IAC byte 147 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 147]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(147))],
  )
  assert_true(@telnet.Command::from_byte(byte(147)) == None)
}

///|
test "restored matrix strict invalid IAC byte 148 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 148]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(148))],
  )
  assert_true(@telnet.Command::from_byte(byte(148)) == None)
}

///|
test "restored matrix strict invalid IAC byte 149 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 149]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(149))],
  )
  assert_true(@telnet.Command::from_byte(byte(149)) == None)
}

///|
test "restored matrix strict invalid IAC byte 150 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 150]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(150))],
  )
  assert_true(@telnet.Command::from_byte(byte(150)) == None)
}

///|
test "restored matrix strict invalid IAC byte 151 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 151]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(151))],
  )
  assert_true(@telnet.Command::from_byte(byte(151)) == None)
}

///|
test "restored matrix strict invalid IAC byte 152 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 152]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(152))],
  )
  assert_true(@telnet.Command::from_byte(byte(152)) == None)
}

///|
test "restored matrix strict invalid IAC byte 153 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 153]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(153))],
  )
  assert_true(@telnet.Command::from_byte(byte(153)) == None)
}

///|
test "restored matrix strict invalid IAC byte 154 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 154]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(154))],
  )
  assert_true(@telnet.Command::from_byte(byte(154)) == None)
}

///|
test "restored matrix strict invalid IAC byte 155 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 155]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(155))],
  )
  assert_true(@telnet.Command::from_byte(byte(155)) == None)
}

///|
test "restored matrix strict invalid IAC byte 156 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 156]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(156))],
  )
  assert_true(@telnet.Command::from_byte(byte(156)) == None)
}

///|
test "restored matrix strict invalid IAC byte 157 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 157]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(157))],
  )
  assert_true(@telnet.Command::from_byte(byte(157)) == None)
}

///|
test "restored matrix strict invalid IAC byte 158 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 158]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(158))],
  )
  assert_true(@telnet.Command::from_byte(byte(158)) == None)
}

///|
test "restored matrix strict invalid IAC byte 159 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 159]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(159))],
  )
  assert_true(@telnet.Command::from_byte(byte(159)) == None)
}

///|
test "restored matrix strict invalid IAC byte 160 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 160]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(160))],
  )
  assert_true(@telnet.Command::from_byte(byte(160)) == None)
}

///|
test "restored matrix strict invalid IAC byte 161 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 161]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(161))],
  )
  assert_true(@telnet.Command::from_byte(byte(161)) == None)
}

///|
test "restored matrix strict invalid IAC byte 162 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 162]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(162))],
  )
  assert_true(@telnet.Command::from_byte(byte(162)) == None)
}

///|
test "restored matrix strict invalid IAC byte 163 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 163]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(163))],
  )
  assert_true(@telnet.Command::from_byte(byte(163)) == None)
}

///|
test "restored matrix strict invalid IAC byte 164 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 164]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(164))],
  )
  assert_true(@telnet.Command::from_byte(byte(164)) == None)
}

///|
test "restored matrix strict invalid IAC byte 165 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 165]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(165))],
  )
  assert_true(@telnet.Command::from_byte(byte(165)) == None)
}

///|
test "restored matrix strict invalid IAC byte 166 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 166]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(166))],
  )
  assert_true(@telnet.Command::from_byte(byte(166)) == None)
}

///|
test "restored matrix strict invalid IAC byte 167 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 167]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(167))],
  )
  assert_true(@telnet.Command::from_byte(byte(167)) == None)
}

///|
test "restored matrix strict invalid IAC byte 168 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 168]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(168))],
  )
  assert_true(@telnet.Command::from_byte(byte(168)) == None)
}

///|
test "restored matrix strict invalid IAC byte 169 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 169]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(169))],
  )
  assert_true(@telnet.Command::from_byte(byte(169)) == None)
}

///|
test "restored matrix strict invalid IAC byte 170 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 170]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(170))],
  )
  assert_true(@telnet.Command::from_byte(byte(170)) == None)
}

///|
test "restored matrix strict invalid IAC byte 171 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 171]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(171))],
  )
  assert_true(@telnet.Command::from_byte(byte(171)) == None)
}

///|
test "restored matrix strict invalid IAC byte 172 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 172]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(172))],
  )
  assert_true(@telnet.Command::from_byte(byte(172)) == None)
}

///|
test "restored matrix strict invalid IAC byte 173 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 173]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(173))],
  )
  assert_true(@telnet.Command::from_byte(byte(173)) == None)
}

///|
test "restored matrix strict invalid IAC byte 174 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 174]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(174))],
  )
  assert_true(@telnet.Command::from_byte(byte(174)) == None)
}

///|
test "restored matrix strict invalid IAC byte 175 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 175]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(175))],
  )
  assert_true(@telnet.Command::from_byte(byte(175)) == None)
}

///|
test "restored matrix strict invalid IAC byte 176 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 176]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(176))],
  )
  assert_true(@telnet.Command::from_byte(byte(176)) == None)
}

///|
test "restored matrix strict invalid IAC byte 177 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 177]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(177))],
  )
  assert_true(@telnet.Command::from_byte(byte(177)) == None)
}

///|
test "restored matrix strict invalid IAC byte 178 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 178]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(178))],
  )
  assert_true(@telnet.Command::from_byte(byte(178)) == None)
}

///|
test "restored matrix strict invalid IAC byte 179 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 179]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(179))],
  )
  assert_true(@telnet.Command::from_byte(byte(179)) == None)
}

///|
test "restored matrix strict invalid IAC byte 180 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 180]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(180))],
  )
  assert_true(@telnet.Command::from_byte(byte(180)) == None)
}

///|
test "restored matrix strict invalid IAC byte 181 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 181]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(181))],
  )
  assert_true(@telnet.Command::from_byte(byte(181)) == None)
}

///|
test "restored matrix strict invalid IAC byte 182 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 182]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(182))],
  )
  assert_true(@telnet.Command::from_byte(byte(182)) == None)
}

///|
test "restored matrix strict invalid IAC byte 183 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 183]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(183))],
  )
  assert_true(@telnet.Command::from_byte(byte(183)) == None)
}

///|
test "restored matrix strict invalid IAC byte 184 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 184]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(184))],
  )
  assert_true(@telnet.Command::from_byte(byte(184)) == None)
}

///|
test "restored matrix strict invalid IAC byte 185 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 185]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(185))],
  )
  assert_true(@telnet.Command::from_byte(byte(185)) == None)
}

///|
test "restored matrix strict invalid IAC byte 186 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 186]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(186))],
  )
  assert_true(@telnet.Command::from_byte(byte(186)) == None)
}

///|
test "restored matrix strict invalid IAC byte 187 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 187]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(187))],
  )
  assert_true(@telnet.Command::from_byte(byte(187)) == None)
}

///|
test "restored matrix strict invalid IAC byte 188 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 188]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(188))],
  )
  assert_true(@telnet.Command::from_byte(byte(188)) == None)
}

///|
test "restored matrix strict invalid IAC byte 189 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 189]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(189))],
  )
  assert_true(@telnet.Command::from_byte(byte(189)) == None)
}

///|
test "restored matrix strict invalid IAC byte 190 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 190]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(190))],
  )
  assert_true(@telnet.Command::from_byte(byte(190)) == None)
}

///|
test "restored matrix strict invalid IAC byte 191 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 191]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(191))],
  )
  assert_true(@telnet.Command::from_byte(byte(191)) == None)
}

///|
test "restored matrix strict invalid IAC byte 192 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 192]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(192))],
  )
  assert_true(@telnet.Command::from_byte(byte(192)) == None)
}

///|
test "restored matrix strict invalid IAC byte 193 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 193]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(193))],
  )
  assert_true(@telnet.Command::from_byte(byte(193)) == None)
}

///|
test "restored matrix strict invalid IAC byte 194 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 194]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(194))],
  )
  assert_true(@telnet.Command::from_byte(byte(194)) == None)
}

///|
test "restored matrix strict invalid IAC byte 195 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 195]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(195))],
  )
  assert_true(@telnet.Command::from_byte(byte(195)) == None)
}

///|
test "restored matrix strict invalid IAC byte 196 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 196]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(196))],
  )
  assert_true(@telnet.Command::from_byte(byte(196)) == None)
}

///|
test "restored matrix strict invalid IAC byte 197 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 197]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(197))],
  )
  assert_true(@telnet.Command::from_byte(byte(197)) == None)
}

///|
test "restored matrix strict invalid IAC byte 198 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 198]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(198))],
  )
  assert_true(@telnet.Command::from_byte(byte(198)) == None)
}

///|
test "restored matrix strict invalid IAC byte 199 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 199]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(199))],
  )
  assert_true(@telnet.Command::from_byte(byte(199)) == None)
}

///|
test "restored matrix strict invalid IAC byte 200 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 200]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(200))],
  )
  assert_true(@telnet.Command::from_byte(byte(200)) == None)
}

///|
test "restored matrix strict invalid IAC byte 201 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 201]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(201))],
  )
  assert_true(@telnet.Command::from_byte(byte(201)) == None)
}

///|
test "restored matrix strict invalid IAC byte 202 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 202]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(202))],
  )
  assert_true(@telnet.Command::from_byte(byte(202)) == None)
}

///|
test "restored matrix strict invalid IAC byte 203 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 203]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(203))],
  )
  assert_true(@telnet.Command::from_byte(byte(203)) == None)
}

///|
test "restored matrix strict invalid IAC byte 204 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 204]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(204))],
  )
  assert_true(@telnet.Command::from_byte(byte(204)) == None)
}

///|
test "restored matrix strict invalid IAC byte 205 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 205]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(205))],
  )
  assert_true(@telnet.Command::from_byte(byte(205)) == None)
}

///|
test "restored matrix strict invalid IAC byte 206 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 206]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(206))],
  )
  assert_true(@telnet.Command::from_byte(byte(206)) == None)
}

///|
test "restored matrix strict invalid IAC byte 207 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 207]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(207))],
  )
  assert_true(@telnet.Command::from_byte(byte(207)) == None)
}

///|
test "restored matrix strict invalid IAC byte 208 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 208]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(208))],
  )
  assert_true(@telnet.Command::from_byte(byte(208)) == None)
}

///|
test "restored matrix strict invalid IAC byte 209 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 209]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(209))],
  )
  assert_true(@telnet.Command::from_byte(byte(209)) == None)
}

///|
test "restored matrix strict invalid IAC byte 210 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 210]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(210))],
  )
  assert_true(@telnet.Command::from_byte(byte(210)) == None)
}

///|
test "restored matrix strict invalid IAC byte 211 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 211]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(211))],
  )
  assert_true(@telnet.Command::from_byte(byte(211)) == None)
}

///|
test "restored matrix strict invalid IAC byte 212 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 212]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(212))],
  )
  assert_true(@telnet.Command::from_byte(byte(212)) == None)
}

///|
test "restored matrix strict invalid IAC byte 213 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 213]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(213))],
  )
  assert_true(@telnet.Command::from_byte(byte(213)) == None)
}

///|
test "restored matrix strict invalid IAC byte 214 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 214]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(214))],
  )
  assert_true(@telnet.Command::from_byte(byte(214)) == None)
}

///|
test "restored matrix strict invalid IAC byte 215 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 215]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(215))],
  )
  assert_true(@telnet.Command::from_byte(byte(215)) == None)
}

///|
test "restored matrix strict invalid IAC byte 216 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 216]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(216))],
  )
  assert_true(@telnet.Command::from_byte(byte(216)) == None)
}

///|
test "restored matrix strict invalid IAC byte 217 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 217]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(217))],
  )
  assert_true(@telnet.Command::from_byte(byte(217)) == None)
}

///|
test "restored matrix strict invalid IAC byte 218 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 218]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(218))],
  )
  assert_true(@telnet.Command::from_byte(byte(218)) == None)
}

///|
test "restored matrix strict invalid IAC byte 219 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 219]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(219))],
  )
  assert_true(@telnet.Command::from_byte(byte(219)) == None)
}

///|
test "restored matrix strict invalid IAC byte 220 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 220]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(220))],
  )
  assert_true(@telnet.Command::from_byte(byte(220)) == None)
}

///|
test "restored matrix strict invalid IAC byte 221 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 221]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(221))],
  )
  assert_true(@telnet.Command::from_byte(byte(221)) == None)
}

///|
test "restored matrix strict invalid IAC byte 222 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 222]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(222))],
  )
  assert_true(@telnet.Command::from_byte(byte(222)) == None)
}

///|
test "restored matrix strict invalid IAC byte 223 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 223]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(223))],
  )
  assert_true(@telnet.Command::from_byte(byte(223)) == None)
}

///|
test "restored matrix strict invalid IAC byte 224 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 224]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(224))],
  )
  assert_true(@telnet.Command::from_byte(byte(224)) == None)
}

///|
test "restored matrix strict invalid IAC byte 225 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 225]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(225))],
  )
  assert_true(@telnet.Command::from_byte(byte(225)) == None)
}

///|
test "restored matrix strict invalid IAC byte 226 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 226]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(226))],
  )
  assert_true(@telnet.Command::from_byte(byte(226)) == None)
}

///|
test "restored matrix strict invalid IAC byte 227 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 227]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(227))],
  )
  assert_true(@telnet.Command::from_byte(byte(227)) == None)
}

///|
test "restored matrix strict invalid IAC byte 228 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 228]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(228))],
  )
  assert_true(@telnet.Command::from_byte(byte(228)) == None)
}

///|
test "restored matrix strict invalid IAC byte 229 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 229]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(229))],
  )
  assert_true(@telnet.Command::from_byte(byte(229)) == None)
}

///|
test "restored matrix strict invalid IAC byte 230 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 230]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(230))],
  )
  assert_true(@telnet.Command::from_byte(byte(230)) == None)
}

///|
test "restored matrix strict invalid IAC byte 231 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 231]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(231))],
  )
  assert_true(@telnet.Command::from_byte(byte(231)) == None)
}

///|
test "restored matrix strict invalid IAC byte 232 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 232]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(232))],
  )
  assert_true(@telnet.Command::from_byte(byte(232)) == None)
}

///|
test "restored matrix strict invalid IAC byte 233 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 233]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(233))],
  )
  assert_true(@telnet.Command::from_byte(byte(233)) == None)
}

///|
test "restored matrix strict invalid IAC byte 234 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 234]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(234))],
  )
  assert_true(@telnet.Command::from_byte(byte(234)) == None)
}

///|
test "restored matrix strict invalid IAC byte 235 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 235]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(235))],
  )
  assert_true(@telnet.Command::from_byte(byte(235)) == None)
}

///|
test "restored matrix strict invalid IAC byte 236 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 236]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(236))],
  )
  assert_true(@telnet.Command::from_byte(byte(236)) == None)
}

///|
test "restored matrix strict invalid IAC byte 237 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 237]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(237))],
  )
  assert_true(@telnet.Command::from_byte(byte(237)) == None)
}

///|
test "restored matrix strict invalid IAC byte 238 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 238]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(238))],
  )
  assert_true(@telnet.Command::from_byte(byte(238)) == None)
}

///|
test "restored matrix strict invalid IAC byte 239 reports error" {
  let result = @telnet.Parser::default().feed(bytes([255, 239]))
  assert_true(result.bytes_consumed == 2)
  assert_true(
    result.events ==
    [err(@telnet.TelnetErrorKind::InvalidCommandByte, 1, Some(239))],
  )
  assert_true(@telnet.Command::from_byte(byte(239)) == None)
}

///|
test "restored matrix split iac_iac at 0 matches whole parse" {
  restored_matrix_assert_split([255, 255], 0, [data([255])])
}

///|
test "restored matrix split iac_iac at 1 matches whole parse" {
  restored_matrix_assert_split([255, 255], 1, [data([255])])
}

///|
test "restored matrix split iac_iac at 2 matches whole parse" {
  restored_matrix_assert_split([255, 255], 2, [data([255])])
}

///|
test "restored matrix split iac_nop at 0 matches whole parse" {
  restored_matrix_assert_split([255, 241], 0, [cmd(@telnet.Command::NOP)])
}

///|
test "restored matrix split iac_nop at 1 matches whole parse" {
  restored_matrix_assert_split([255, 241], 1, [cmd(@telnet.Command::NOP)])
}

///|
test "restored matrix split iac_nop at 2 matches whole parse" {
  restored_matrix_assert_split([255, 241], 2, [cmd(@telnet.Command::NOP)])
}

///|
test "restored matrix split will_echo at 0 matches whole parse" {
  restored_matrix_assert_split([255, 251, 1], 0, [
    neg(@telnet.NegotiationVerb::Will, 1),
  ])
}

///|
test "restored matrix split will_echo at 1 matches whole parse" {
  restored_matrix_assert_split([255, 251, 1], 1, [
    neg(@telnet.NegotiationVerb::Will, 1),
  ])
}

///|
test "restored matrix split will_echo at 2 matches whole parse" {
  restored_matrix_assert_split([255, 251, 1], 2, [
    neg(@telnet.NegotiationVerb::Will, 1),
  ])
}

///|
test "restored matrix split will_echo at 3 matches whole parse" {
  restored_matrix_assert_split([255, 251, 1], 3, [
    neg(@telnet.NegotiationVerb::Will, 1),
  ])
}

///|
test "restored matrix split wont_echo at 0 matches whole parse" {
  restored_matrix_assert_split([255, 252, 1], 0, [
    neg(@telnet.NegotiationVerb::Wont, 1),
  ])
}

///|
test "restored matrix split wont_echo at 1 matches whole parse" {
  restored_matrix_assert_split([255, 252, 1], 1, [
    neg(@telnet.NegotiationVerb::Wont, 1),
  ])
}

///|
test "restored matrix split wont_echo at 2 matches whole parse" {
  restored_matrix_assert_split([255, 252, 1], 2, [
    neg(@telnet.NegotiationVerb::Wont, 1),
  ])
}

///|
test "restored matrix split wont_echo at 3 matches whole parse" {
  restored_matrix_assert_split([255, 252, 1], 3, [
    neg(@telnet.NegotiationVerb::Wont, 1),
  ])
}

///|
test "restored matrix split do_naws at 0 matches whole parse" {
  restored_matrix_assert_split([255, 253, 31], 0, [
    neg(@telnet.NegotiationVerb::Do, 31),
  ])
}

///|
test "restored matrix split do_naws at 1 matches whole parse" {
  restored_matrix_assert_split([255, 253, 31], 1, [
    neg(@telnet.NegotiationVerb::Do, 31),
  ])
}

///|
test "restored matrix split do_naws at 2 matches whole parse" {
  restored_matrix_assert_split([255, 253, 31], 2, [
    neg(@telnet.NegotiationVerb::Do, 31),
  ])
}

///|
test "restored matrix split do_naws at 3 matches whole parse" {
  restored_matrix_assert_split([255, 253, 31], 3, [
    neg(@telnet.NegotiationVerb::Do, 31),
  ])
}

///|
test "restored matrix split dont_naws at 0 matches whole parse" {
  restored_matrix_assert_split([255, 254, 31], 0, [
    neg(@telnet.NegotiationVerb::Dont, 31),
  ])
}

///|
test "restored matrix split dont_naws at 1 matches whole parse" {
  restored_matrix_assert_split([255, 254, 31], 1, [
    neg(@telnet.NegotiationVerb::Dont, 31),
  ])
}

///|
test "restored matrix split dont_naws at 2 matches whole parse" {
  restored_matrix_assert_split([255, 254, 31], 2, [
    neg(@telnet.NegotiationVerb::Dont, 31),
  ])
}

///|
test "restored matrix split dont_naws at 3 matches whole parse" {
  restored_matrix_assert_split([255, 254, 31], 3, [
    neg(@telnet.NegotiationVerb::Dont, 31),
  ])
}

///|
test "restored matrix split ttype_send at 0 matches whole parse" {
  restored_matrix_assert_split([255, 250, 24, 1, 255, 240], 0, [sb(24, [1])])
}

///|
test "restored matrix split ttype_send at 1 matches whole parse" {
  restored_matrix_assert_split([255, 250, 24, 1, 255, 240], 1, [sb(24, [1])])
}

///|
test "restored matrix split ttype_send at 2 matches whole parse" {
  restored_matrix_assert_split([255, 250, 24, 1, 255, 240], 2, [sb(24, [1])])
}

///|
test "restored matrix split ttype_send at 3 matches whole parse" {
  restored_matrix_assert_split([255, 250, 24, 1, 255, 240], 3, [sb(24, [1])])
}

///|
test "restored matrix split ttype_send at 4 matches whole parse" {
  restored_matrix_assert_split([255, 250, 24, 1, 255, 240], 4, [sb(24, [1])])
}

///|
test "restored matrix split ttype_send at 5 matches whole parse" {
  restored_matrix_assert_split([255, 250, 24, 1, 255, 240], 5, [sb(24, [1])])
}

///|
test "restored matrix split ttype_send at 6 matches whole parse" {
  restored_matrix_assert_split([255, 250, 24, 1, 255, 240], 6, [sb(24, [1])])
}

///|
test "restored matrix split naws_iac at 0 matches whole parse" {
  restored_matrix_assert_split(
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    0,
    [sb(31, [0, 255, 0, 24])],
  )
}

///|
test "restored matrix split naws_iac at 1 matches whole parse" {
  restored_matrix_assert_split(
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    1,
    [sb(31, [0, 255, 0, 24])],
  )
}

///|
test "restored matrix split naws_iac at 2 matches whole parse" {
  restored_matrix_assert_split(
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    2,
    [sb(31, [0, 255, 0, 24])],
  )
}

///|
test "restored matrix split naws_iac at 3 matches whole parse" {
  restored_matrix_assert_split(
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    3,
    [sb(31, [0, 255, 0, 24])],
  )
}

///|
test "restored matrix split naws_iac at 4 matches whole parse" {
  restored_matrix_assert_split(
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    4,
    [sb(31, [0, 255, 0, 24])],
  )
}

///|
test "restored matrix split naws_iac at 5 matches whole parse" {
  restored_matrix_assert_split(
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    5,
    [sb(31, [0, 255, 0, 24])],
  )
}

///|
test "restored matrix split naws_iac at 6 matches whole parse" {
  restored_matrix_assert_split(
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    6,
    [sb(31, [0, 255, 0, 24])],
  )
}

///|
test "restored matrix split naws_iac at 7 matches whole parse" {
  restored_matrix_assert_split(
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    7,
    [sb(31, [0, 255, 0, 24])],
  )
}

///|
test "restored matrix split naws_iac at 8 matches whole parse" {
  restored_matrix_assert_split(
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    8,
    [sb(31, [0, 255, 0, 24])],
  )
}

///|
test "restored matrix split naws_iac at 9 matches whole parse" {
  restored_matrix_assert_split(
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    9,
    [sb(31, [0, 255, 0, 24])],
  )
}

///|
test "restored matrix split naws_iac at 10 matches whole parse" {
  restored_matrix_assert_split(
    [255, 250, 31, 0, 255, 255, 0, 24, 255, 240],
    10,
    [sb(31, [0, 255, 0, 24])],
  )
}

///|
test "restored matrix split mixed_ayt at 0 matches whole parse" {
  restored_matrix_assert_split([65, 255, 246, 66], 0, [
    data([65]),
    cmd(@telnet.Command::AYT),
    data([66]),
  ])
}

///|
test "restored matrix split mixed_ayt at 1 matches whole parse" {
  restored_matrix_assert_split([65, 255, 246, 66], 1, [
    data([65]),
    cmd(@telnet.Command::AYT),
    data([66]),
  ])
}

///|
test "restored matrix split mixed_ayt at 2 matches whole parse" {
  restored_matrix_assert_split([65, 255, 246, 66], 2, [
    data([65]),
    cmd(@telnet.Command::AYT),
    data([66]),
  ])
}

///|
test "restored matrix split mixed_ayt at 3 matches whole parse" {
  restored_matrix_assert_split([65, 255, 246, 66], 3, [
    data([65]),
    cmd(@telnet.Command::AYT),
    data([66]),
  ])
}

///|
test "restored matrix split mixed_ayt at 4 matches whole parse" {
  restored_matrix_assert_split([65, 255, 246, 66], 4, [
    data([65]),
    cmd(@telnet.Command::AYT),
    data([66]),
  ])
}

///|
test "restored scenario terminal resize decodes sequential NAWS updates" {
  let parser = @telnet.Parser::default()
  let enabled = parser.feed(bytes([255, 253, 31, 255, 251, 31]))
  assert_true(
    enabled.events ==
    [
      neg(@telnet.NegotiationVerb::Do, 31),
      neg(@telnet.NegotiationVerb::Will, 31),
    ],
  )
  let resize1 = enabled.parser.feed(
    bytes([255, 250, 31, 0, 80, 0, 24, 255, 240]),
  )
  assert_true(resize1.events == [sb(31, [0, 80, 0, 24])])
  match restored_payload_at(resize1.events, 0) {
    @telnet.OptionPayload::Naws(size) => {
      assert_true(size.columns == (80).to_uint16())
      assert_true(size.rows == (24).to_uint16())
    }
    _ => assert_true(false)
  }
  let resize2 = resize1.parser.feed(
    bytes([255, 250, 31, 0, 132, 0, 43, 255, 240]),
  )
  assert_true(resize2.events == [sb(31, [0, 132, 0, 43])])
  match restored_payload_at(resize2.events, 0) {
    @telnet.OptionPayload::Naws(size) => {
      assert_true(size.columns == (132).to_uint16())
      assert_true(size.rows == (43).to_uint16())
    }
    _ => assert_true(false)
  }
}
