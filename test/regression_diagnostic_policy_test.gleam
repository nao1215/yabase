import gleam/list
import gleam/option.{None}
import yabase as y

pub fn original_letter_case_survives_folding_test() {
  assert y.decode_int("1X0", using: y.Base16, up_to: None)
    == Error(y.InvalidCharacter("X", 1))
  assert y.decode("0X", using: y.Base16) == Error(y.InvalidCharacter("X", 1))
  assert y.decode_bech32("BC1BQQQQQ") == Error(y.InvalidCharacter("B", 3))
  assert y.decode_multibase("f12Z3") == Error(y.InvalidCharacter("Z", 3))
}

pub fn crockford_ignored_hyphens_still_count_in_source_positions_test() {
  assert y.decode("A--!", using: y.Base32Crockford)
    == Error(y.InvalidCharacter("!", 3))
  assert y.decode("--A!", using: y.Base32Crockford)
    == Error(y.InvalidCharacter("!", 3))
  assert y.decode("A--u", using: y.Base32Crockford)
    == Error(y.InvalidCharacter("u", 3))
  assert y.decode("--A-\u{0301}", using: y.Base32Crockford)
    == Error(y.InvalidCharacter("-\u{0301}", 3))
  assert y.decode("-\u{0301}", using: y.Base32Crockford)
    == Error(y.InvalidCharacter("-\u{0301}", 0))
  assert y.decode("A-\u{0301}", using: y.Base32Crockford)
    == Error(y.InvalidCharacter("-\u{0301}", 1))
}

pub fn crockford_check_keeps_body_before_check_priority_test() {
  assert y.decode("A--!\u{017F}", using: y.Base32CrockfordCheck)
    == Error(y.InvalidCharacter("!", 3))
  assert y.decode("S\u{017F}", using: y.Base32CrockfordCheck)
    == Error(y.InvalidChecksum)
  assert y.decode("Ss", using: y.Base32CrockfordCheck) == Ok(<<25>>)
  assert y.decode("O-I-L", using: y.Base32Crockford) == Ok(<<0, 33>>)
}

pub fn adobe_fixed_trim_set_has_eleven_members_test() {
  let whitespace = [
    "\t",
    "\n",
    "\u{000B}",
    "\u{000C}",
    "\r",
    " ",
    "\u{0085}",
    "\u{200E}",
    "\u{200F}",
    "\u{2028}",
    "\u{2029}",
  ]
  list.each(whitespace, fn(ws) {
    assert y.decode(ws <> "<~v~>" <> ws, using: y.AdobeAscii85)
      == Error(y.InvalidCharacter("v", 3))
    assert y.decode(ws <> "<~z~>" <> ws, using: y.AdobeAscii85)
      == Ok(<<0, 0, 0, 0>>)
    assert y.decode(ws <> "<~>" <> ws, using: y.AdobeAscii85) == Ok(<<>>)
  })
}

pub fn adobe_trim_does_not_expand_to_nbsp_or_body_whitespace_test() {
  assert y.decode("\u{00A0}<~z~>", using: y.AdobeAscii85)
    == Error(y.MissingDelimiter("<~", 0))
  assert y.decode("<~z~>\u{00A0}", using: y.AdobeAscii85)
    == Error(y.MissingDelimiter("~>", 6))
  assert y.decode("<~z\u{200E}~>", using: y.AdobeAscii85)
    == Error(y.InvalidCharacter("\u{200E}", 3))
}

pub fn missing_delimiters_report_original_insertion_boundaries_test() {
  assert y.decode("", using: y.AdobeAscii85)
    == Error(y.MissingDelimiter("<~", 0))
  assert y.decode(" \r\n\t", using: y.AdobeAscii85)
    == Error(y.MissingDelimiter("<~", 3))
  assert y.decode("  x~>  ", using: y.AdobeAscii85)
    == Error(y.MissingDelimiter("<~", 2))
  assert y.decode("  <~z  ", using: y.AdobeAscii85)
    == Error(y.MissingDelimiter("~>", 5))
  assert y.decode("\r\n<~z", using: y.AdobeAscii85)
    == Error(y.MissingDelimiter("~>", 4))
  assert y.decode("<~", using: y.AdobeAscii85)
    == Error(y.MissingDelimiter("~>", 2))
  assert y.decode("~>", using: y.AdobeAscii85)
    == Error(y.MissingDelimiter("<~", 0))
}

pub fn delimiter_insertion_boundary_handles_combining_graphemes_test() {
  assert y.decode("<~z~>\u{0301}", using: y.AdobeAscii85)
    == Error(y.MissingDelimiter("~>", 5))
  assert y.decode(" \u{0301}<~z~>", using: y.AdobeAscii85)
    == Error(y.MissingDelimiter("<~", 0))
}

pub fn legacy_length_payload_is_not_rewritten_as_original_offset_test() {
  assert y.decode("  <~!~>  ", using: y.AdobeAscii85)
    == Error(y.InvalidLength(3))
  assert y.decode_multibase("fF") == Error(y.InvalidLength(1))
}

pub fn unicode_dq_and_real_padding_keep_original_symbols_test() {
  assert y.encode(<<0>>, using: y.Base64Dq) == Ok("ああ・・")
  assert y.decode("ああ・・", using: y.Base64Dq) == Ok(<<0>>)
  assert y.decode("あい!う", using: y.Base64Dq)
    == Error(y.InvalidCharacter("!", 2))
  assert y.decode("あ\u{0301}あ・・", using: y.Base64Dq)
    == Error(y.InvalidCharacter("あ\u{0301}", 0))
  assert y.decode("・あ・・", using: y.Base64Dq)
    == Error(y.InvalidCharacter("・", 0))
  assert y.decode("QUJD=BCD", using: y.Base64)
    == Error(y.InvalidCharacter("=", 4))
}

pub fn prefix_is_a_whole_original_grapheme_test() {
  assert y.decode_multibase("f\u{0301}00")
    == Error(y.UnsupportedPrefix("f\u{0301}"))
  assert y.decode_multibase("") == Error(y.UnsupportedPrefix(""))
}
