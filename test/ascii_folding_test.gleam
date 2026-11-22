//// Case-insensitive decoders fold ASCII letters only. Before, the whole
//// input went through string.uppercase / string.lowercase, so U+0131
//// (dotless i) passed as "I" and U+212A (Kelvin sign) passed as "k".

import yabase/base32/clockwork
import yabase/base32/crockford
import yabase/base32/hex
import yabase/base32/rfc4648
import yabase/base32/zbase32
import yabase/base36
import yabase/core/error.{InvalidCharacter}

pub fn rfc4648_rejects_dotless_i_test() -> Nil {
  assert rfc4648.decode("MZXW6YTBO\u{0131}======")
    == Error(InvalidCharacter("\u{0131}", 9))
}

pub fn hex_rejects_dotless_i_test() -> Nil {
  assert hex.decode("\u{0131}0======") == Error(InvalidCharacter("\u{0131}", 0))
}

pub fn clockwork_rejects_dotless_i_test() -> Nil {
  assert clockwork.decode("0\u{0131}") == Error(InvalidCharacter("\u{0131}", 1))
}

pub fn zbase32_rejects_kelvin_sign_test() -> Nil {
  assert zbase32.decode("y\u{212A}") == Error(InvalidCharacter("\u{212A}", 1))
}

pub fn base36_rejects_kelvin_sign_test() -> Nil {
  assert base36.decode("\u{212A}") == Error(InvalidCharacter("\u{212A}", 0))
}

pub fn crockford_rejects_kelvin_sign_test() -> Nil {
  assert crockford.decode("\u{212A}") == Error(InvalidCharacter("\u{212A}", 0))
}

pub fn ascii_letters_still_fold_test() -> Nil {
  assert rfc4648.decode("mzxw6ytboi======") == Ok(<<"foobar":utf8>>)
  assert zbase32.decode("YK") == zbase32.decode("yk")
  assert base36.decode("K") == Ok(<<20>>)
}
