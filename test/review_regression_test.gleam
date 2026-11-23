import codec_test_support
import yabase.{InvalidCharacter, InvalidChecksum}

pub fn base85_rejects_combining_suffix_test() -> Nil {
  assert yabase.decode("Hello\u{0301}", using: yabase.Z85)
    == Error(InvalidCharacter("o\u{0301}", 4))
  assert yabase.decode("Hello\u{0301}", using: yabase.Rfc1924Base85)
    == Error(InvalidCharacter("o\u{0301}", 4))
}

pub fn crockford_checksum_rejects_non_ascii_case_alias_test() -> Nil {
  assert codec_test_support.encode(<<25>>, using: yabase.Base32CrockfordCheck)
    == "SS"
  assert yabase.decode("S\u{017F}", using: yabase.Base32CrockfordCheck)
    == Error(InvalidChecksum)
  assert yabase.decode("Ss", using: yabase.Base32CrockfordCheck) == Ok(<<25>>)
}

pub fn byte_decoders_report_the_entire_invalid_grapheme_test() -> Nil {
  assert yabase.decode("00A\u{0301}0", using: yabase.Base16)
    == Error(InvalidCharacter("A\u{0301}", 2))
  assert yabase.decode("QUJDQ\u{0301}Q==", using: yabase.Base64)
    == Error(InvalidCharacter("Q\u{0301}", 4))
}

pub fn ignored_hyphens_do_not_shift_invalid_grapheme_positions_test() -> Nil {
  assert yabase.decode("-\u{0301}", using: yabase.Base32Crockford)
    == Error(InvalidCharacter("-\u{0301}", 0))
  assert yabase.decode("A-\u{0301}", using: yabase.Base32Crockford)
    == Error(InvalidCharacter("-\u{0301}", 1))
}
