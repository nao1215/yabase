import yabase/base64/dq
import yabase/base64/nopadding
import yabase/base64/standard
import yabase/base64/urlsafe
import yabase/base64/urlsafe_nopadding
import yabase/core/error.{InvalidCharacter, InvalidLength, NonCanonical}

// ===== Standard =====

// --- Fixed vectors (RFC 4648 section 10) ---

pub fn standard_encode_empty_test() -> Nil {
  assert standard.encode(<<>>) == ""
}

pub fn standard_encode_f_test() -> Nil {
  assert standard.encode(<<"f":utf8>>) == "Zg=="
}

pub fn standard_encode_fo_test() -> Nil {
  assert standard.encode(<<"fo":utf8>>) == "Zm8="
}

pub fn standard_encode_foo_test() -> Nil {
  assert standard.encode(<<"foo":utf8>>) == "Zm9v"
}

pub fn standard_encode_foob_test() -> Nil {
  assert standard.encode(<<"foob":utf8>>) == "Zm9vYg=="
}

pub fn standard_encode_fooba_test() -> Nil {
  assert standard.encode(<<"fooba":utf8>>) == "Zm9vYmE="
}

pub fn standard_encode_foobar_test() -> Nil {
  assert standard.encode(<<"foobar":utf8>>) == "Zm9vYmFy"
}

pub fn standard_decode_empty_test() -> Nil {
  assert standard.decode("") == Ok(<<>>)
}

pub fn standard_decode_foobar_test() -> Nil {
  assert standard.decode("Zm9vYmFy") == Ok(<<"foobar":utf8>>)
}

pub fn standard_decode_with_padding_test() -> Nil {
  assert standard.decode("Zg==") == Ok(<<"f":utf8>>)
}

// --- Decode error cases ---

pub fn standard_decode_truncated_1char_test() -> Nil {
  assert standard.decode("Z") == Error(InvalidLength(1))
}

pub fn standard_decode_truncated_2char_test() -> Nil {
  assert standard.decode("Zg") == Error(InvalidLength(2))
}

pub fn standard_decode_truncated_3char_test() -> Nil {
  assert standard.decode("Zg=") == Error(InvalidLength(3))
}

pub fn standard_decode_invalid_char_test() -> Nil {
  assert standard.decode("Z!==") == Error(InvalidCharacter("!", 1))
}

// scure-base bad input vectors (paulmillr/scure-base)
pub fn scure_bad_a_triple_eq_test() -> Nil {
  // "A===" -> invalid (only 1 data char with 3 pad)
  assert case standard.decode("A===") {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

pub fn scure_bad_aa_single_eq_test() -> Nil {
  // "AA=" -> 3 chars, not multiple of 4
  assert standard.decode("AA=") == Error(InvalidLength(3))
}

pub fn scure_bad_aaaa_8eq_test() -> Nil {
  // "AAAA====" -> 8 chars but excess padding
  assert case standard.decode("AAAA====") {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

pub fn scure_bad_aaa_test() -> Nil {
  // "AAA" -> 3 chars, not multiple of 4
  assert standard.decode("AAA") == Error(InvalidLength(3))
}

pub fn scure_bad_pad_prefix_test() -> Nil {
  // "=Zm8" -> pad at start
  assert case standard.decode("=Zm8") {
    Error(InvalidCharacter("=", 0)) -> True
    _ -> False
  }
}

pub fn scure_bad_aaaaa_test() -> Nil {
  // "AAAAA" -> 5 chars, not multiple of 4
  assert standard.decode("AAAAA") == Error(InvalidLength(5))
}

pub fn scure_bad_single_eq_test() -> Nil {
  assert standard.decode("=") == Error(InvalidLength(1))
}

pub fn scure_bad_double_eq_test() -> Nil {
  assert standard.decode("==") == Error(InvalidLength(2))
}

// --- CRLF rejection (RFC 4648 section 3.3) ---
//
// Whitespace is rejected with `InvalidCharacter` carrying the
// offending byte and its position; the alphabet check runs before
// the length check so the diagnostic points at the real fault
// rather than at a misleading length mismatch (#7).

pub fn standard_decode_rejects_lf_test() -> Nil {
  assert standard.decode("Zm9v\n") == Error(InvalidCharacter("\n", 4))
}

pub fn standard_decode_rejects_crlf_in_middle_test() -> Nil {
  // "Zg==\r\n" - \r\n is one grapheme cluster in Unicode at position 4.
  assert standard.decode("Zg==\r\n") == Error(InvalidCharacter("\r\n", 4))
}

pub fn standard_decode_rejects_space_in_middle_test() -> Nil {
  // The headline #7 reproduction: a space inside an otherwise
  // 4-aligned input must surface as InvalidCharacter, not
  // InvalidLength.
  assert standard.decode("SGk =") == Error(InvalidCharacter(" ", 3))
}

// --- Padding-then-trailing-data regression ---

pub fn standard_decode_data_after_double_pad_test() -> Nil {
  // "Zg==AAAA" must be rejected, not silently truncated
  assert case standard.decode("Zg==AAAA") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn standard_decode_data_after_single_pad_test() -> Nil {
  // "Zm8=AAAA" must be rejected
  assert case standard.decode("Zm8=AAAA") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// --- Roundtrip corpus ---

pub fn standard_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert standard.decode(standard.encode(data)) == Ok(data)
}

pub fn standard_roundtrip_empty_test() -> Nil {
  assert standard.decode(standard.encode(<<>>)) == Ok(<<>>)
}

pub fn standard_roundtrip_single_zero_test() -> Nil {
  assert standard.decode(standard.encode(<<0>>)) == Ok(<<0>>)
}

pub fn standard_roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert standard.decode(standard.encode(data)) == Ok(data)
}

pub fn standard_roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0x80>>
  assert standard.decode(standard.encode(data)) == Ok(data)
}

// ===== URL-safe =====

pub fn urlsafe_encode_test() -> Nil {
  let data = <<251, 255, 254>>
  let encoded = urlsafe.encode(data)
  assert encoded == "-__-"
}

pub fn urlsafe_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert urlsafe.decode(urlsafe.encode(data)) == Ok(data)
}

pub fn urlsafe_roundtrip_empty_test() -> Nil {
  assert urlsafe.decode(urlsafe.encode(<<>>)) == Ok(<<>>)
}

pub fn urlsafe_decode_truncated_test() -> Nil {
  assert urlsafe.decode("ab") == Error(InvalidLength(2))
}

pub fn urlsafe_decode_rejects_lf_test() -> Nil {
  // Whitespace surfaces as InvalidCharacter with its position (#7),
  // not as a misleading InvalidLength.
  assert urlsafe.decode("Zm9v\n") == Error(InvalidCharacter("\n", 4))
}

pub fn urlsafe_decode_data_after_double_pad_test() -> Nil {
  assert case urlsafe.decode("Zg==AAAA") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn urlsafe_decode_data_after_single_pad_test() -> Nil {
  assert case urlsafe.decode("Zm8=AAAA") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// ===== No padding =====

pub fn nopadding_encode_f_test() -> Nil {
  assert nopadding.encode(<<"f":utf8>>) == "Zg"
}

pub fn nopadding_encode_fo_test() -> Nil {
  assert nopadding.encode(<<"fo":utf8>>) == "Zm8"
}

pub fn nopadding_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert nopadding.decode(nopadding.encode(data)) == Ok(data)
}

pub fn nopadding_roundtrip_empty_test() -> Nil {
  assert nopadding.decode(nopadding.encode(<<>>)) == Ok(<<>>)
}

pub fn nopadding_decode_invalid_length_mod4_eq_1_test() -> Nil {
  // Length 5 -> 5 % 4 == 1 -> invalid
  assert nopadding.decode("AAAAA") == Error(InvalidLength(5))
}

pub fn nopadding_decode_rejects_padding_test() -> Nil {
  // "Zg==" is valid padded Base64 for "f", but nopadding must reject it
  assert nopadding.decode("Zg==") == Error(InvalidCharacter("=", 2))
}

pub fn nopadding_decode_rejects_single_pad_test() -> Nil {
  assert nopadding.decode("Zm8=") == Error(InvalidCharacter("=", 3))
}

// ===== URL-safe no padding =====

pub fn urlsafe_nopadding_decode_rejects_double_pad_test() -> Nil {
  assert urlsafe_nopadding.decode("Zg==") == Error(InvalidCharacter("=", 2))
}

pub fn urlsafe_nopadding_decode_rejects_single_pad_test() -> Nil {
  assert urlsafe_nopadding.decode("Zm8=") == Error(InvalidCharacter("=", 3))
}

// ===== DQ =====

pub fn dq_encode_empty_test() -> Nil {
  assert dq.encode(<<>>) == ""
}

pub fn dq_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert dq.decode(dq.encode(data)) == Ok(data)
}

pub fn dq_roundtrip_with_padding_test() -> Nil {
  let data = <<"Hi":utf8>>
  assert dq.decode(dq.encode(data)) == Ok(data)
}

pub fn dq_roundtrip_empty_test() -> Nil {
  assert dq.decode(dq.encode(<<>>)) == Ok(<<>>)
}

pub fn dq_decode_truncated_test() -> Nil {
  // 1 or 2 or 3 hiragana is invalid (must be multiple of 4)
  assert dq.decode("あ") == Error(InvalidLength(1))
}

pub fn dq_decode_truncated_2_test() -> Nil {
  assert dq.decode("あい") == Error(InvalidLength(2))
}

pub fn dq_decode_truncated_3_test() -> Nil {
  assert dq.decode("あいう") == Error(InvalidLength(3))
}

pub fn dq_decode_data_after_double_pad_test() -> Nil {
  // Encode "f" -> 4 chars with 2 pads, then append valid chars
  let encoded = dq.encode(<<"f":utf8>>)
  let with_extra = encoded <> "あいうえ"
  assert case dq.decode(with_extra) {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// --- DQ InvalidCharacter at each position ---

pub fn dq_decode_invalid_char_pos0_double_pad_test() -> Nil {
  // "X" + valid + pad + pad  (invalid at position 0, double-pad branch)
  assert dq.decode("Xい・・") == Error(InvalidCharacter("X", 0))
}

pub fn dq_decode_invalid_char_pos1_double_pad_test() -> Nil {
  // valid + "X" + pad + pad  (invalid at position 1, double-pad branch)
  assert dq.decode("あX・・") == Error(InvalidCharacter("X", 1))
}

pub fn dq_decode_invalid_char_pos0_single_pad_test() -> Nil {
  // "X" + valid + valid + pad  (invalid at position 0, single-pad branch)
  assert dq.decode("Xいう・") == Error(InvalidCharacter("X", 0))
}

pub fn dq_decode_invalid_char_pos1_single_pad_test() -> Nil {
  assert dq.decode("あXう・") == Error(InvalidCharacter("X", 1))
}

pub fn dq_decode_invalid_char_pos2_single_pad_test() -> Nil {
  assert dq.decode("あいX・") == Error(InvalidCharacter("X", 2))
}

pub fn dq_decode_invalid_char_no_pad_test() -> Nil {
  // All 4 positions unpadded
  assert dq.decode("Xいうえ") == Error(InvalidCharacter("X", 0))
  assert dq.decode("あXうえ") == Error(InvalidCharacter("X", 1))
  assert dq.decode("あいXえ") == Error(InvalidCharacter("X", 2))
  assert dq.decode("あいうX") == Error(InvalidCharacter("X", 3))
}

// --- DQ cross-reference vectors (shogo82148/base64dq) ---

// RFC 4648 examples in DQ encoding
pub fn dq_rfc4648_f_test() -> Nil {
  assert dq.encode(<<"f":utf8>>) == "はむ・・"
  assert dq.decode("はむ・・") == Ok(<<"f":utf8>>)
}

pub fn dq_rfc4648_fo_test() -> Nil {
  assert dq.encode(<<"fo":utf8>>) == "はらび・"
  assert dq.decode("はらび・") == Ok(<<"fo":utf8>>)
}

pub fn dq_rfc4648_foo_test() -> Nil {
  assert dq.encode(<<"foo":utf8>>) == "はらぶげ"
  assert dq.decode("はらぶげ") == Ok(<<"foo":utf8>>)
}

pub fn dq_rfc4648_foob_test() -> Nil {
  assert dq.encode(<<"foob":utf8>>) == "はらぶげのむ・・"
  assert dq.decode("はらぶげのむ・・") == Ok(<<"foob":utf8>>)
}

pub fn dq_rfc4648_fooba_test() -> Nil {
  assert dq.encode(<<"fooba":utf8>>) == "はらぶげのらお・"
  assert dq.decode("はらぶげのらお・") == Ok(<<"fooba":utf8>>)
}

pub fn dq_rfc4648_foobar_test() -> Nil {
  assert dq.encode(<<"foobar":utf8>>) == "はらぶげのらかじ"
  assert dq.decode("はらぶげのらかじ") == Ok(<<"foobar":utf8>>)
}

// Wikipedia examples
pub fn dq_wikipedia_sure_dot_test() -> Nil {
  assert dq.encode(<<"sure.":utf8>>) == "へぢにじはてづ・"
  assert dq.decode("へぢにじはてづ・") == Ok(<<"sure.":utf8>>)
}

pub fn dq_wikipedia_sure_test() -> Nil {
  assert dq.encode(<<"sure":utf8>>) == "へぢにじはち・・"
  assert dq.decode("へぢにじはち・・") == Ok(<<"sure":utf8>>)
}

pub fn dq_wikipedia_sur_test() -> Nil {
  assert dq.encode(<<"sur":utf8>>) == "へぢにじ"
  assert dq.decode("へぢにじ") == Ok(<<"sur":utf8>>)
}

pub fn dq_wikipedia_su_test() -> Nil {
  assert dq.encode(<<"su":utf8>>) == "へぢな・"
  assert dq.decode("へぢな・") == Ok(<<"su":utf8>>)
}

// DQ1 password vectors
pub fn dq_dq1_password_vector_1_test() -> Nil {
  let data = <<0x14, 0xFB, 0x9C, 0x03, 0xD9, 0x7E>>
  assert dq.encode(data) == "かたぐへあぶよべ"
  assert dq.decode("かたぐへあぶよべ") == Ok(data)
}

pub fn dq_dq1_password_vector_2_test() -> Nil {
  let data = <<0x14, 0xFB, 0x9C, 0x03, 0xD9>>
  assert dq.encode(data) == "かたぐへあぶゆ・"
  assert dq.decode("かたぐへあぶゆ・") == Ok(data)
}

pub fn dq_dq1_password_vector_3_test() -> Nil {
  let data = <<0x14, 0xFB, 0x9C, 0x03>>
  assert dq.encode(data) == "かたぐへあご・・"
  assert dq.decode("かたぐへあご・・") == Ok(data)
}

// Bigtest: "Twas brillig, and the slithy toves"
pub fn dq_bigtest_test() -> Nil {
  let data = <<"Twas brillig, and the slithy toves":utf8>>
  let expected = "にくほめへじいもへらよがふきよりしういめふらちむほきめよけくせがひねつるまていぜふぢはよへご・・"
  assert dq.encode(data) == expected
  assert dq.decode(expected) == Ok(data)
}

// Corrupt input cases from shogo82148/base64dq
pub fn dq_decode_pad_at_start_test() -> Nil {
  // "・・・・" -> pad at position 0 is invalid
  assert case dq.decode("・・・・") {
    Error(InvalidCharacter("・", 0)) -> True
    _ -> False
  }
}

pub fn dq_decode_pad_after_one_char_test() -> Nil {
  // "が・・・" -> pad at position 1 in first group
  assert case dq.decode("が・・・") {
    Error(InvalidCharacter("・", _)) -> True
    _ -> False
  }
}

// --- DQ error cases ---

pub fn dq_decode_non_hiragana_ascii_test() -> Nil {
  // ASCII "ABCD" is not in the DQ hiragana alphabet
  assert case dq.decode("ABCD") {
    Error(InvalidCharacter("A", 0)) -> True
    _ -> False
  }
}

pub fn dq_decode_non_hiragana_kanji_test() -> Nil {
  // Kanji is not in the DQ alphabet
  assert case dq.decode("漢字漢字") {
    Error(InvalidCharacter(_, 0)) -> True
    _ -> False
  }
}

pub fn dq_decode_stray_char_in_middle_test() -> Nil {
  // 4-char aligned input with invalid first char
  assert case dq.decode("Xいうえ") {
    Error(InvalidCharacter("X", 0)) -> True
    _ -> False
  }
}

// ===== decode_strict (RFC 4648 §3.5 canonical-encoding check) =====

pub fn standard_decode_strict_canonical_passes_test() -> Nil {
  // Canonical encoding of "f" — pad bits in 'g' are zero.
  assert standard.decode_strict("Zg==") == Ok(<<"f":utf8>>)
}

pub fn standard_decode_strict_non_canonical_rejected_test() -> Nil {
  // Non-canonical: "Zh==" decodes to <<0x66>> too, but the pad bits
  // in 'h' are non-zero (canonical form is "Zg==").
  assert standard.decode_strict("Zh==") == Error(NonCanonical)
}

pub fn standard_decode_strict_one_pad_non_canonical_rejected_test() -> Nil {
  // Non-canonical 2-byte input with 1 pad char: "Zm9=" decodes to
  // "fo" the same as the canonical "Zm8=", but the trailing 2 bits
  // of '9' (value 61 = 111101) are non-zero. The canonical form
  // ends in '8' (value 60 = 111100).
  assert standard.decode_strict("Zm9=") == Error(NonCanonical)
}

pub fn standard_decode_strict_full_block_passes_test() -> Nil {
  // Full-block encodings (no padding) cannot be non-canonical —
  // every bit is data, no pad bits exist.
  assert standard.decode_strict("Zm9v") == Ok(<<"foo":utf8>>)
}

pub fn standard_decode_strict_propagates_invalid_character_test() -> Nil {
  // Strict mode should still surface alphabet-validation errors
  // unchanged.
  assert case standard.decode_strict("Z!==") {
    Error(InvalidCharacter("!", 1)) -> True
    _ -> False
  }
}

pub fn standard_decode_strict_propagates_invalid_length_test() -> Nil {
  // Strict mode should still surface length errors unchanged.
  assert case standard.decode_strict("Zg=") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}
