import gleam/option.{None}
import yabase as y

pub fn hex_odd_first_test() {
  assert y.decode_int("!", using: y.Base16, up_to: None)
    == Error(y.InvalidCharacter("!", 0))
}

pub fn hex_odd_last_test() {
  assert y.decode_int("12!", using: y.Base16, up_to: None)
    == Error(y.InvalidCharacter("!", 2))
}

pub fn hex_even_control_test() {
  assert y.decode_int("1!", using: y.Base16, up_to: None)
    == Error(y.InvalidCharacter("!", 1))
}

pub fn hex_unicode_test() {
  assert y.decode_int("é", using: y.Base16, up_to: None)
    == Error(y.InvalidCharacter("é", 0))
}

pub fn hex_leading_mark_test() {
  assert y.decode_int("́", using: y.Base16, up_to: None)
    == Error(y.InvalidCharacter("́", 0))
}

pub fn hex_leading_mark_with_digits_test() {
  assert y.decode_int("́AF", using: y.Base16, up_to: None)
    == Error(y.InvalidCharacter("́", 0))
}

pub fn hex_combined_odd_test() {
  assert y.decode_int("Á", using: y.Base16, up_to: None)
    == Error(y.InvalidCharacter("Á", 0))
}

pub fn hex_combined_even_control_test() {
  assert y.decode_int("ÁF", using: y.Base16, up_to: None)
    == Error(y.InvalidCharacter("Á", 0))
}
