//// Case-insensitive decoders fold ASCII letters only. Before, the whole
//// input went through string.uppercase / string.lowercase, so U+0131
//// (dotless i) passed as "I" and U+212A (Kelvin sign) passed as "k".

import yabase.{InvalidCharacter}

import gleam/string

pub fn rfc4648_rejects_dotless_i_test() -> Nil {
  assert yabase.decode("MZXW6YTBO\u{0131}======", using: yabase.Base32Rfc4648)
    == Error(InvalidCharacter("\u{0131}", 9))
}

pub fn hex_rejects_dotless_i_test() -> Nil {
  assert yabase.decode("\u{0131}0======", using: yabase.Base32Hex)
    == Error(InvalidCharacter("\u{0131}", 0))
}

pub fn clockwork_rejects_dotless_i_test() -> Nil {
  assert yabase.decode("0\u{0131}", using: yabase.Base32Clockwork)
    == Error(InvalidCharacter("\u{0131}", 1))
}

pub fn zbase32_rejects_kelvin_sign_test() -> Nil {
  assert yabase.decode("y\u{212A}", using: yabase.Zbase32)
    == Error(InvalidCharacter("\u{212A}", 1))
}

pub fn base36_rejects_kelvin_sign_test() -> Nil {
  assert yabase.decode("\u{212A}", using: yabase.Base36)
    == Error(InvalidCharacter("\u{212A}", 0))
}

pub fn crockford_rejects_kelvin_sign_test() -> Nil {
  assert yabase.decode("\u{212A}", using: yabase.Base32Crockford)
    == Error(InvalidCharacter("\u{212A}", 0))
}

pub fn ascii_letters_still_fold_test() -> Nil {
  assert yabase.decode("mzxw6ytboi======", using: yabase.Base32Rfc4648)
    == Ok(<<"foobar":utf8>>)
  assert yabase.decode("YK", using: yabase.Zbase32)
    == yabase.decode("yk", using: yabase.Zbase32)
  assert yabase.decode("K", using: yabase.Base36) == Ok(<<20>>)
}

pub fn bech32_rejects_kelvin_sign_before_case_folding_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode(
      <<1, 2, 3>>,
      using: yabase.Bech32Encoding("k", yabase.Bech32m),
    )
  let invalid = "\u{212A}" <> string.uppercase(string.drop_start(encoded, 1))
  assert yabase.decode_bech32(invalid) == Error(InvalidCharacter("\u{212A}", 0))
  let assert Ok(_) = yabase.decode_bech32(string.uppercase(encoded))
  Nil
}
