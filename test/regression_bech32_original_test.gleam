import yabase as y

pub fn bech32_data_first_test() {
  assert y.decode_bech32("bc1!qqqqq") == Error(y.InvalidCharacter("!", 3))
}

pub fn bech32_data_last_test() {
  assert y.decode_bech32("bc1qqqqq!") == Error(y.InvalidCharacter("!", 8))
}

pub fn bech32_last_separator_test() {
  assert y.decode_bech32("a1b1!qqqqq") == Error(y.InvalidCharacter("!", 4))
}

pub fn bech32_uppercase_offset_test() {
  assert y.decode_bech32("BC1!QQQQQ") == Error(y.InvalidCharacter("!", 3))
}

pub fn bech32_unicode_control_test() {
  assert y.decode_bech32("bc1éqqqqq") == Error(y.InvalidCharacter("é", 3))
}

pub fn bech32_data_combined_test() {
  assert y.decode_bech32("bc1q́qqqqq") == Error(y.InvalidCharacter("q́", 3))
}

pub fn bech32_hrp_combined_test() {
  assert y.decode_bech32("b́c1qqqqqq") == Error(y.InvalidCharacter("b́", 0))
}
