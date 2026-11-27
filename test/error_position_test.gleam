//// Error positions of every decoder.
////
//// A mutation testing run showed that almost no test pinned the
//// `position` in `InvalidCharacter`: replacing `pos + 1` with `pos - 1`
//// in a decoder survived. Each case puts the offending character after
//// at least one full group, so a position computed from the wrong
//// group start, or that forgets skipped whitespace, is caught.

import yabase.{InvalidCharacter}

import gleam/list
import gleam/string

pub fn base64_reports_a_misplaced_pad_at_its_index_test() -> Nil {
  assert yabase.decode("QUJD=BCD", using: yabase.Base64)
    == Error(InvalidCharacter("=", 4))
  assert yabase.decode("QUJDQ=CD", using: yabase.Base64)
    == Error(InvalidCharacter("=", 5))
  assert yabase.decode("QUJDQU=D", using: yabase.Base64)
    == Error(InvalidCharacter("=", 6))
  assert yabase.decode("QUJD=A==", using: yabase.Base64)
    == Error(InvalidCharacter("=", 4))
  assert yabase.decode("QUJDQ=A=", using: yabase.Base64)
    == Error(InvalidCharacter("=", 5))
  assert yabase.decode("QUJD=BCD", using: yabase.Base64UrlSafe)
    == Error(InvalidCharacter("=", 4))
  assert yabase.decode("QUJDQ=CD", using: yabase.Base64UrlSafe)
    == Error(InvalidCharacter("=", 5))
  assert yabase.decode("QUJDQU=D", using: yabase.Base64UrlSafe)
    == Error(InvalidCharacter("=", 6))
}

pub fn base64_dq_reports_the_grapheme_index_test() -> Nil {
  assert yabase.decode("あいう!", using: yabase.Base64Dq)
    == Error(InvalidCharacter("!", 3))
  assert yabase.decode("あい!う", using: yabase.Base64Dq)
    == Error(InvalidCharacter("!", 2))
}

pub fn base32_reports_a_misplaced_pad_at_its_index_test() -> Nil {
  assert yabase.decode("MFRGG=A=", using: yabase.Base32Rfc4648)
    == Error(InvalidCharacter("=", 5))
  assert yabase.decode("MF=GGZDF", using: yabase.Base32Rfc4648)
    == Error(InvalidCharacter("=", 2))
  assert yabase.decode("C5H66=A=", using: yabase.Base32Hex)
    == Error(InvalidCharacter("=", 5))
  assert yabase.decode("C5=66P35", using: yabase.Base32Hex)
    == Error(InvalidCharacter("=", 2))
}

pub fn base32_variants_report_an_invalid_character_at_its_index_test() -> Nil {
  assert yabase.decode("CSQPYRK1!", using: yabase.Base32Clockwork)
    == Error(InvalidCharacter("!", 8))
  assert yabase.decode("cfmzhxbx!", using: yabase.Zbase32)
    == Error(InvalidCharacter("!", 8))
}

pub fn ascii85_family_reports_an_invalid_character_at_its_index_test() -> Nil {
  assert yabase.decode("87cURD]i,\"Ebo80~", using: yabase.Ascii85)
    == Error(InvalidCharacter("~", 15))
  assert yabase.decode("87cU RD]v,\"Ebo80", using: yabase.Ascii85)
    == Error(InvalidCharacter("v", 8))
  assert yabase.decode("<~87cU RD]v,\"Ebo80~>", using: yabase.AdobeAscii85)
    == Error(InvalidCharacter("v", 10))
  assert yabase.decode("HelloWorl~", using: yabase.Z85)
    == Error(InvalidCharacter("~", 9))
  assert yabase.decode("Hello~orld", using: yabase.Z85)
    == Error(InvalidCharacter("~", 5))
  assert yabase.decode("HelloWorl\"", using: yabase.Rfc1924Base85)
    == Error(InvalidCharacter("\"", 9))
  assert yabase.decode("Hello\"orld", using: yabase.Rfc1924Base85)
    == Error(InvalidCharacter("\"", 5))
}

/// The invalid "v" must be reported at its grapheme index after every
/// kind of skipped whitespace, inside a group and between groups, and
/// after the `z` / `y` shortcuts.
pub fn ascii85_counts_every_skipped_grapheme_test() -> Nil {
  let whitespace = [" ", "\t", "\n", "\r", "\r\n", "\u{000C}"]
  list.each(whitespace, fn(ws) {
    let inside = "87cU" <> ws <> "RD]"
    let between = "87cUR" <> ws <> "D]"
    assert yabase.decode(inside <> "v", using: yabase.Ascii85)
      == Error(InvalidCharacter("v", string.length(inside)))
    assert yabase.decode(between <> "v", using: yabase.Ascii85)
      == Error(InvalidCharacter("v", string.length(between)))
  })
  assert yabase.decode("zD]v", using: yabase.Ascii85)
    == Error(InvalidCharacter("v", 3))
  assert yabase.decode("yD]v", using: yabase.Ascii85)
    == Error(InvalidCharacter("v", 3))
}

pub fn adobe_ascii85_counts_every_skipped_grapheme_test() -> Nil {
  let whitespace = [" ", "\t", "\n", "\r", "\u{000C}"]
  list.each(whitespace, fn(ws) {
    let inside = "<~87cU" <> ws <> "RD]"
    let between = "<~87cUR" <> ws <> "D]"
    assert yabase.decode(inside <> "v~>", using: yabase.AdobeAscii85)
      == Error(InvalidCharacter("v", string.length(inside)))
    assert yabase.decode(between <> "v~>", using: yabase.AdobeAscii85)
      == Error(InvalidCharacter("v", string.length(between)))
  })
  assert yabase.decode("<~zD]v~>", using: yabase.AdobeAscii85)
    == Error(InvalidCharacter("v", 5))
}

pub fn base45_and_base91_report_an_invalid_character_at_its_index_test() -> Nil {
  assert yabase.decode("BB8~A", using: yabase.Base45)
    == Error(InvalidCharacter("~", 3))
  assert yabase.decode("fPNKd'", using: yabase.Base91)
    == Error(InvalidCharacter("'", 5))
}

// The second and third symbol of a Base45 group, and a symbol after
// whitespace or CR LF in Base91, are reported at their own index.
pub fn base45_and_base91_count_the_symbols_before_an_invalid_one_test() -> Nil {
  assert yabase.decode("A!A", using: yabase.Base45)
    == Error(InvalidCharacter("!", 1))
  assert yabase.decode("AA!", using: yabase.Base45)
    == Error(InvalidCharacter("!", 2))
  assert yabase.decode("AB -", using: yabase.Base91)
    == Error(InvalidCharacter("-", 3))
  assert yabase.decode("AB\r\n-", using: yabase.Base91)
    == Error(InvalidCharacter("-", 3))
}

// A misplaced Base64Dq pad, and a character after a pad, are reported at
// their grapheme index in every group.
pub fn base64_dq_reports_a_misplaced_pad_at_its_index_test() -> Nil {
  assert yabase.decode("あ・ちけ", using: yabase.Base64Dq)
    == Error(InvalidCharacter("・", 1))
  assert yabase.decode("あち・け", using: yabase.Base64Dq)
    == Error(InvalidCharacter("・", 2))
  assert yabase.decode("あちけえ・あちけ", using: yabase.Base64Dq)
    == Error(InvalidCharacter("・", 4))
  assert yabase.decode("あちけえあ・ちけ", using: yabase.Base64Dq)
    == Error(InvalidCharacter("・", 5))
  assert yabase.decode("あちけえあち・け", using: yabase.Base64Dq)
    == Error(InvalidCharacter("・", 6))
  assert yabase.decode("あち・x", using: yabase.Base64Dq)
    == Error(InvalidCharacter("x", 3))
}
