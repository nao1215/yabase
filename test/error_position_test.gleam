//// Error positions of every decoder.
////
//// A mutation testing run showed that almost no test pinned the
//// `position` in `InvalidCharacter`: replacing `pos + 1` with `pos - 1`
//// in a decoder survived. Each case puts the offending character after
//// at least one full group, so a position computed from the wrong
//// group start, or that forgets skipped whitespace, is caught.

import gleam/list
import gleam/string
import yabase/adobe_ascii85
import yabase/ascii85
import yabase/base32/clockwork
import yabase/base32/hex
import yabase/base32/rfc4648
import yabase/base32/zbase32
import yabase/base45
import yabase/base64/dq
import yabase/base64/standard
import yabase/base64/urlsafe
import yabase/base91
import yabase/core/error.{InvalidCharacter}
import yabase/rfc1924_base85
import yabase/z85

pub fn base64_reports_a_misplaced_pad_at_its_index_test() -> Nil {
  assert standard.decode("QUJD=BCD") == Error(InvalidCharacter("=", 4))
  assert standard.decode("QUJDQ=CD") == Error(InvalidCharacter("=", 5))
  assert standard.decode("QUJDQU=D") == Error(InvalidCharacter("=", 6))
  assert standard.decode("QUJD=A==") == Error(InvalidCharacter("=", 4))
  assert standard.decode("QUJDQ=A=") == Error(InvalidCharacter("=", 5))
  assert urlsafe.decode("QUJD=BCD") == Error(InvalidCharacter("=", 4))
  assert urlsafe.decode("QUJDQ=CD") == Error(InvalidCharacter("=", 5))
  assert urlsafe.decode("QUJDQU=D") == Error(InvalidCharacter("=", 6))
}

pub fn base64_dq_reports_the_grapheme_index_test() -> Nil {
  assert dq.decode("あいう!") == Error(InvalidCharacter("!", 3))
  assert dq.decode("あい!う") == Error(InvalidCharacter("!", 2))
}

pub fn base32_reports_a_misplaced_pad_at_its_index_test() -> Nil {
  assert rfc4648.decode("MFRGG=A=") == Error(InvalidCharacter("=", 5))
  assert rfc4648.decode("MF=GGZDF") == Error(InvalidCharacter("=", 2))
  assert hex.decode("C5H66=A=") == Error(InvalidCharacter("=", 5))
  assert hex.decode("C5=66P35") == Error(InvalidCharacter("=", 2))
}

pub fn base32_variants_report_an_invalid_character_at_its_index_test() -> Nil {
  assert clockwork.decode("CSQPYRK1!") == Error(InvalidCharacter("!", 8))
  assert zbase32.decode("cfmzhxbx!") == Error(InvalidCharacter("!", 8))
}

pub fn ascii85_family_reports_an_invalid_character_at_its_index_test() -> Nil {
  assert ascii85.decode("87cURD]i,\"Ebo80~") == Error(InvalidCharacter("~", 15))
  assert ascii85.decode("87cU RD]v,\"Ebo80") == Error(InvalidCharacter("v", 8))
  assert adobe_ascii85.decode("<~87cU RD]v,\"Ebo80~>")
    == Error(InvalidCharacter("v", 10))
  assert z85.decode("HelloWorl~") == Error(InvalidCharacter("~", 9))
  assert z85.decode("Hello~orld") == Error(InvalidCharacter("~", 5))
  assert rfc1924_base85.decode("HelloWorl\"")
    == Error(InvalidCharacter("\"", 9))
  assert rfc1924_base85.decode("Hello\"orld")
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
    assert ascii85.decode(inside <> "v")
      == Error(InvalidCharacter("v", string.length(inside)))
    assert ascii85.decode(between <> "v")
      == Error(InvalidCharacter("v", string.length(between)))
  })
  assert ascii85.decode("zD]v") == Error(InvalidCharacter("v", 3))
  assert ascii85.decode("yD]v") == Error(InvalidCharacter("v", 3))
}

pub fn adobe_ascii85_counts_every_skipped_grapheme_test() -> Nil {
  let whitespace = [" ", "\t", "\n", "\r", "\u{000C}"]
  list.each(whitespace, fn(ws) {
    let inside = "<~87cU" <> ws <> "RD]"
    let between = "<~87cUR" <> ws <> "D]"
    assert adobe_ascii85.decode(inside <> "v~>")
      == Error(InvalidCharacter("v", string.length(inside)))
    assert adobe_ascii85.decode(between <> "v~>")
      == Error(InvalidCharacter("v", string.length(between)))
  })
  assert adobe_ascii85.decode("<~zD]v~>") == Error(InvalidCharacter("v", 5))
}

pub fn base45_and_base91_report_an_invalid_character_at_its_index_test() -> Nil {
  assert base45.decode("BB8~A") == Error(InvalidCharacter("~", 3))
  assert base91.decode("fPNKd'") == Error(InvalidCharacter("'", 5))
}
