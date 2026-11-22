import yabase/base16
import yabase/base32/crockford
import yabase/base64/standard
import yabase/core/error.{InvalidCharacter, InvalidChecksum}
import yabase/rfc1924_base85
import yabase/z85

pub fn base85_rejects_combining_suffix_test() -> Nil {
  assert z85.decode("Hello\u{0301}") == Error(InvalidCharacter("o\u{0301}", 4))
  assert rfc1924_base85.decode("Hello\u{0301}")
    == Error(InvalidCharacter("o\u{0301}", 4))
}

pub fn crockford_checksum_rejects_non_ascii_case_alias_test() -> Nil {
  assert crockford.encode_check(<<25>>) == "SS"
  assert crockford.decode_check("S\u{017F}") == Error(InvalidChecksum)
  assert crockford.decode_check("Ss") == Ok(<<25>>)
}

pub fn byte_decoders_report_the_entire_invalid_grapheme_test() -> Nil {
  assert base16.decode("00A\u{0301}0")
    == Error(InvalidCharacter("A\u{0301}", 2))
  assert standard.decode("QUJDQ\u{0301}Q==")
    == Error(InvalidCharacter("Q\u{0301}", 4))
}

pub fn ignored_hyphens_do_not_shift_invalid_grapheme_positions_test() -> Nil {
  assert crockford.decode("-\u{0301}")
    == Error(InvalidCharacter("-\u{0301}", 0))
  assert crockford.decode("A-\u{0301}")
    == Error(InvalidCharacter("-\u{0301}", 1))
}
