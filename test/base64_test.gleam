import codec_test_support
import yabase.{InvalidCharacter, InvalidLength, NonCanonical}

// ===== Standard =====

// --- Fixed vectors (RFC 4648 section 10) ---

pub fn standard_encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base64) == ""
}

pub fn standard_encode_f_test() -> Nil {
  assert codec_test_support.encode(<<"f":utf8>>, using: yabase.Base64) == "Zg=="
}

pub fn standard_encode_fo_test() -> Nil {
  assert codec_test_support.encode(<<"fo":utf8>>, using: yabase.Base64)
    == "Zm8="
}

pub fn standard_encode_foo_test() -> Nil {
  assert codec_test_support.encode(<<"foo":utf8>>, using: yabase.Base64)
    == "Zm9v"
}

pub fn standard_encode_foob_test() -> Nil {
  assert codec_test_support.encode(<<"foob":utf8>>, using: yabase.Base64)
    == "Zm9vYg=="
}

pub fn standard_encode_fooba_test() -> Nil {
  assert codec_test_support.encode(<<"fooba":utf8>>, using: yabase.Base64)
    == "Zm9vYmE="
}

pub fn standard_encode_foobar_test() -> Nil {
  assert codec_test_support.encode(<<"foobar":utf8>>, using: yabase.Base64)
    == "Zm9vYmFy"
}

pub fn standard_decode_empty_test() -> Nil {
  assert yabase.decode("", using: yabase.Base64) == Ok(<<>>)
}

pub fn standard_decode_foobar_test() -> Nil {
  assert yabase.decode("Zm9vYmFy", using: yabase.Base64)
    == Ok(<<"foobar":utf8>>)
}

pub fn standard_decode_with_padding_test() -> Nil {
  assert yabase.decode("Zg==", using: yabase.Base64) == Ok(<<"f":utf8>>)
}

// --- Decode error cases ---

pub fn standard_decode_truncated_1char_test() -> Nil {
  assert yabase.decode("Z", using: yabase.Base64) == Error(InvalidLength(1))
}

pub fn standard_decode_truncated_2char_test() -> Nil {
  assert yabase.decode("Zg", using: yabase.Base64) == Error(InvalidLength(2))
}

pub fn standard_decode_truncated_3char_test() -> Nil {
  assert yabase.decode("Zg=", using: yabase.Base64) == Error(InvalidLength(3))
}

pub fn standard_decode_invalid_char_test() -> Nil {
  assert yabase.decode("Z!==", using: yabase.Base64)
    == Error(InvalidCharacter("!", 1))
}

// scure-base bad input vectors (paulmillr/scure-base)
pub fn scure_bad_a_triple_eq_test() -> Nil {
  // "A===" -> invalid (only 1 data char with 3 pad)
  assert case yabase.decode("A===", using: yabase.Base64) {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

pub fn scure_bad_aa_single_eq_test() -> Nil {
  // "AA=" -> 3 chars, not multiple of 4
  assert yabase.decode("AA=", using: yabase.Base64) == Error(InvalidLength(3))
}

pub fn scure_bad_aaaa_8eq_test() -> Nil {
  // "AAAA====" -> 8 chars but excess padding
  assert case yabase.decode("AAAA====", using: yabase.Base64) {
    Error(InvalidCharacter(_, _)) -> True
    _ -> False
  }
}

pub fn scure_bad_aaa_test() -> Nil {
  // "AAA" -> 3 chars, not multiple of 4
  assert yabase.decode("AAA", using: yabase.Base64) == Error(InvalidLength(3))
}

pub fn scure_bad_pad_prefix_test() -> Nil {
  // "=Zm8" -> pad at start
  assert case yabase.decode("=Zm8", using: yabase.Base64) {
    Error(InvalidCharacter("=", 0)) -> True
    _ -> False
  }
}

pub fn scure_bad_aaaaa_test() -> Nil {
  // "AAAAA" -> 5 chars, not multiple of 4
  assert yabase.decode("AAAAA", using: yabase.Base64) == Error(InvalidLength(5))
}

pub fn scure_bad_single_eq_test() -> Nil {
  assert yabase.decode("=", using: yabase.Base64) == Error(InvalidLength(1))
}

pub fn scure_bad_double_eq_test() -> Nil {
  assert yabase.decode("==", using: yabase.Base64) == Error(InvalidLength(2))
}

// --- CRLF rejection (RFC 4648 section 3.3) ---
//
// Whitespace is rejected with `InvalidCharacter` carrying the
// offending byte and its position; the alphabet check runs before
// the length check so the diagnostic points at the real fault
// rather than at a misleading length mismatch (#7).

pub fn standard_decode_rejects_lf_test() -> Nil {
  assert yabase.decode("Zm9v\n", using: yabase.Base64)
    == Error(InvalidCharacter("\n", 4))
}

pub fn standard_decode_rejects_crlf_in_middle_test() -> Nil {
  // "Zg==\r\n" - \r\n is one grapheme cluster in Unicode at position 4.
  assert yabase.decode("Zg==\r\n", using: yabase.Base64)
    == Error(InvalidCharacter("\r\n", 4))
}

pub fn standard_decode_rejects_space_in_middle_test() -> Nil {
  // The headline #7 reproduction: a space inside an otherwise
  // 4-aligned input must surface as InvalidCharacter, not
  // InvalidLength.
  assert yabase.decode("SGk =", using: yabase.Base64)
    == Error(InvalidCharacter(" ", 3))
}

// --- Padding-then-trailing-data regression ---

pub fn standard_decode_data_after_double_pad_test() -> Nil {
  // "Zg==AAAA" must be rejected, not silently truncated
  assert case yabase.decode("Zg==AAAA", using: yabase.Base64) {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn standard_decode_data_after_single_pad_test() -> Nil {
  // "Zm8=AAAA" must be rejected
  assert case yabase.decode("Zm8=AAAA", using: yabase.Base64) {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// --- Roundtrip corpus ---

pub fn standard_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64),
      using: yabase.Base64,
    )
    == Ok(data)
}

pub fn standard_roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base64),
      using: yabase.Base64,
    )
    == Ok(<<>>)
}

pub fn standard_roundtrip_single_zero_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<0>>, using: yabase.Base64),
      using: yabase.Base64,
    )
    == Ok(<<0>>)
}

pub fn standard_roundtrip_leading_zeros_test() -> Nil {
  let data = <<0, 0, 0, 42>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64),
      using: yabase.Base64,
    )
    == Ok(data)
}

pub fn standard_roundtrip_high_bits_test() -> Nil {
  let data = <<0xff, 0xfe, 0x80>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64),
      using: yabase.Base64,
    )
    == Ok(data)
}

// ===== URL-safe =====

pub fn urlsafe_encode_test() -> Nil {
  let data = <<251, 255, 254>>
  let encoded = codec_test_support.encode(data, using: yabase.Base64UrlSafe)
  assert encoded == "-__-"
}

pub fn urlsafe_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64UrlSafe),
      using: yabase.Base64UrlSafe,
    )
    == Ok(data)
}

pub fn urlsafe_roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base64UrlSafe),
      using: yabase.Base64UrlSafe,
    )
    == Ok(<<>>)
}

pub fn urlsafe_decode_truncated_test() -> Nil {
  assert yabase.decode("ab", using: yabase.Base64UrlSafe)
    == Error(InvalidLength(2))
}

pub fn urlsafe_decode_rejects_lf_test() -> Nil {
  // Whitespace surfaces as InvalidCharacter with its position (#7),
  // not as a misleading InvalidLength.
  assert yabase.decode("Zm9v\n", using: yabase.Base64UrlSafe)
    == Error(InvalidCharacter("\n", 4))
}

pub fn urlsafe_decode_data_after_double_pad_test() -> Nil {
  assert case yabase.decode("Zg==AAAA", using: yabase.Base64UrlSafe) {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn urlsafe_decode_data_after_single_pad_test() -> Nil {
  assert case yabase.decode("Zm8=AAAA", using: yabase.Base64UrlSafe) {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// ===== No padding =====

pub fn nopadding_encode_f_test() -> Nil {
  assert codec_test_support.encode(<<"f":utf8>>, using: yabase.Base64NoPadding)
    == "Zg"
}

pub fn nopadding_encode_fo_test() -> Nil {
  assert codec_test_support.encode(<<"fo":utf8>>, using: yabase.Base64NoPadding)
    == "Zm8"
}

pub fn nopadding_roundtrip_test() -> Nil {
  let data = <<"Hello, World!":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64NoPadding),
      using: yabase.Base64NoPadding,
    )
    == Ok(data)
}

pub fn nopadding_roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base64NoPadding),
      using: yabase.Base64NoPadding,
    )
    == Ok(<<>>)
}

pub fn nopadding_decode_invalid_length_mod4_eq_1_test() -> Nil {
  // Length 5 -> 5 % 4 == 1 -> invalid
  assert yabase.decode("AAAAA", using: yabase.Base64NoPadding)
    == Error(InvalidLength(5))
}

pub fn nopadding_decode_rejects_padding_test() -> Nil {
  // "Zg==" is valid padded Base64 for "f", but nopadding must reject it
  assert yabase.decode("Zg==", using: yabase.Base64NoPadding)
    == Error(InvalidCharacter("=", 2))
}

pub fn nopadding_decode_rejects_single_pad_test() -> Nil {
  assert yabase.decode("Zm8=", using: yabase.Base64NoPadding)
    == Error(InvalidCharacter("=", 3))
}

// ===== URL-safe no padding =====

pub fn urlsafe_nopadding_decode_rejects_double_pad_test() -> Nil {
  assert yabase.decode("Zg==", using: yabase.Base64UrlSafeNoPadding)
    == Error(InvalidCharacter("=", 2))
}

pub fn urlsafe_nopadding_decode_rejects_single_pad_test() -> Nil {
  assert yabase.decode("Zm8=", using: yabase.Base64UrlSafeNoPadding)
    == Error(InvalidCharacter("=", 3))
}

// ===== DQ =====

pub fn dq_encode_empty_test() -> Nil {
  assert codec_test_support.encode(<<>>, using: yabase.Base64Dq) == ""
}

pub fn dq_roundtrip_test() -> Nil {
  let data = <<"Hello":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64Dq),
      using: yabase.Base64Dq,
    )
    == Ok(data)
}

pub fn dq_roundtrip_with_padding_test() -> Nil {
  let data = <<"Hi":utf8>>
  assert yabase.decode(
      codec_test_support.encode(data, using: yabase.Base64Dq),
      using: yabase.Base64Dq,
    )
    == Ok(data)
}

pub fn dq_roundtrip_empty_test() -> Nil {
  assert yabase.decode(
      codec_test_support.encode(<<>>, using: yabase.Base64Dq),
      using: yabase.Base64Dq,
    )
    == Ok(<<>>)
}

pub fn dq_decode_truncated_test() -> Nil {
  // 1 or 2 or 3 hiragana is invalid (must be multiple of 4)
  assert yabase.decode("あ", using: yabase.Base64Dq) == Error(InvalidLength(1))
}

pub fn dq_decode_truncated_2_test() -> Nil {
  assert yabase.decode("あい", using: yabase.Base64Dq) == Error(InvalidLength(2))
}

pub fn dq_decode_truncated_3_test() -> Nil {
  assert yabase.decode("あいう", using: yabase.Base64Dq) == Error(InvalidLength(3))
}

pub fn dq_decode_data_after_double_pad_test() -> Nil {
  // Encode "f" -> 4 chars with 2 pads, then append valid chars
  let encoded = codec_test_support.encode(<<"f":utf8>>, using: yabase.Base64Dq)
  let with_extra = encoded <> "あいうえ"
  assert case yabase.decode(with_extra, using: yabase.Base64Dq) {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// --- DQ InvalidCharacter at each position ---

pub fn dq_decode_invalid_char_pos0_double_pad_test() -> Nil {
  // "X" + valid + pad + pad  (invalid at position 0, double-pad branch)
  assert yabase.decode("Xい・・", using: yabase.Base64Dq)
    == Error(InvalidCharacter("X", 0))
}

pub fn dq_decode_invalid_char_pos1_double_pad_test() -> Nil {
  // valid + "X" + pad + pad  (invalid at position 1, double-pad branch)
  assert yabase.decode("あX・・", using: yabase.Base64Dq)
    == Error(InvalidCharacter("X", 1))
}

pub fn dq_decode_invalid_char_pos0_single_pad_test() -> Nil {
  // "X" + valid + valid + pad  (invalid at position 0, single-pad branch)
  assert yabase.decode("Xいう・", using: yabase.Base64Dq)
    == Error(InvalidCharacter("X", 0))
}

pub fn dq_decode_invalid_char_pos1_single_pad_test() -> Nil {
  assert yabase.decode("あXう・", using: yabase.Base64Dq)
    == Error(InvalidCharacter("X", 1))
}

pub fn dq_decode_invalid_char_pos2_single_pad_test() -> Nil {
  assert yabase.decode("あいX・", using: yabase.Base64Dq)
    == Error(InvalidCharacter("X", 2))
}

pub fn dq_decode_invalid_char_no_pad_test() -> Nil {
  // All 4 positions unpadded
  assert yabase.decode("Xいうえ", using: yabase.Base64Dq)
    == Error(InvalidCharacter("X", 0))
  assert yabase.decode("あXうえ", using: yabase.Base64Dq)
    == Error(InvalidCharacter("X", 1))
  assert yabase.decode("あいXえ", using: yabase.Base64Dq)
    == Error(InvalidCharacter("X", 2))
  assert yabase.decode("あいうX", using: yabase.Base64Dq)
    == Error(InvalidCharacter("X", 3))
}

// --- DQ cross-reference vectors (shogo82148/base64dq) ---

// RFC 4648 examples in DQ encoding
pub fn dq_rfc4648_f_test() -> Nil {
  assert codec_test_support.encode(<<"f":utf8>>, using: yabase.Base64Dq)
    == "はむ・・"
  assert yabase.decode("はむ・・", using: yabase.Base64Dq) == Ok(<<"f":utf8>>)
}

pub fn dq_rfc4648_fo_test() -> Nil {
  assert codec_test_support.encode(<<"fo":utf8>>, using: yabase.Base64Dq)
    == "はらび・"
  assert yabase.decode("はらび・", using: yabase.Base64Dq) == Ok(<<"fo":utf8>>)
}

pub fn dq_rfc4648_foo_test() -> Nil {
  assert codec_test_support.encode(<<"foo":utf8>>, using: yabase.Base64Dq)
    == "はらぶげ"
  assert yabase.decode("はらぶげ", using: yabase.Base64Dq) == Ok(<<"foo":utf8>>)
}

pub fn dq_rfc4648_foob_test() -> Nil {
  assert codec_test_support.encode(<<"foob":utf8>>, using: yabase.Base64Dq)
    == "はらぶげのむ・・"
  assert yabase.decode("はらぶげのむ・・", using: yabase.Base64Dq)
    == Ok(<<"foob":utf8>>)
}

pub fn dq_rfc4648_fooba_test() -> Nil {
  assert codec_test_support.encode(<<"fooba":utf8>>, using: yabase.Base64Dq)
    == "はらぶげのらお・"
  assert yabase.decode("はらぶげのらお・", using: yabase.Base64Dq)
    == Ok(<<"fooba":utf8>>)
}

pub fn dq_rfc4648_foobar_test() -> Nil {
  assert codec_test_support.encode(<<"foobar":utf8>>, using: yabase.Base64Dq)
    == "はらぶげのらかじ"
  assert yabase.decode("はらぶげのらかじ", using: yabase.Base64Dq)
    == Ok(<<"foobar":utf8>>)
}

// Wikipedia examples
pub fn dq_wikipedia_sure_dot_test() -> Nil {
  assert codec_test_support.encode(<<"sure.":utf8>>, using: yabase.Base64Dq)
    == "へぢにじはてづ・"
  assert yabase.decode("へぢにじはてづ・", using: yabase.Base64Dq)
    == Ok(<<"sure.":utf8>>)
}

pub fn dq_wikipedia_sure_test() -> Nil {
  assert codec_test_support.encode(<<"sure":utf8>>, using: yabase.Base64Dq)
    == "へぢにじはち・・"
  assert yabase.decode("へぢにじはち・・", using: yabase.Base64Dq)
    == Ok(<<"sure":utf8>>)
}

pub fn dq_wikipedia_sur_test() -> Nil {
  assert codec_test_support.encode(<<"sur":utf8>>, using: yabase.Base64Dq)
    == "へぢにじ"
  assert yabase.decode("へぢにじ", using: yabase.Base64Dq) == Ok(<<"sur":utf8>>)
}

pub fn dq_wikipedia_su_test() -> Nil {
  assert codec_test_support.encode(<<"su":utf8>>, using: yabase.Base64Dq)
    == "へぢな・"
  assert yabase.decode("へぢな・", using: yabase.Base64Dq) == Ok(<<"su":utf8>>)
}

// DQ1 password vectors
pub fn dq_dq1_password_vector_1_test() -> Nil {
  let data = <<0x14, 0xFB, 0x9C, 0x03, 0xD9, 0x7E>>
  assert codec_test_support.encode(data, using: yabase.Base64Dq) == "かたぐへあぶよべ"
  assert yabase.decode("かたぐへあぶよべ", using: yabase.Base64Dq) == Ok(data)
}

pub fn dq_dq1_password_vector_2_test() -> Nil {
  let data = <<0x14, 0xFB, 0x9C, 0x03, 0xD9>>
  assert codec_test_support.encode(data, using: yabase.Base64Dq) == "かたぐへあぶゆ・"
  assert yabase.decode("かたぐへあぶゆ・", using: yabase.Base64Dq) == Ok(data)
}

pub fn dq_dq1_password_vector_3_test() -> Nil {
  let data = <<0x14, 0xFB, 0x9C, 0x03>>
  assert codec_test_support.encode(data, using: yabase.Base64Dq) == "かたぐへあご・・"
  assert yabase.decode("かたぐへあご・・", using: yabase.Base64Dq) == Ok(data)
}

// Bigtest: "Twas brillig, and the slithy toves"
pub fn dq_bigtest_test() -> Nil {
  let data = <<"Twas brillig, and the slithy toves":utf8>>
  let expected = "にくほめへじいもへらよがふきよりしういめふらちむほきめよけくせがひねつるまていぜふぢはよへご・・"
  assert codec_test_support.encode(data, using: yabase.Base64Dq) == expected
  assert yabase.decode(expected, using: yabase.Base64Dq) == Ok(data)
}

// Corrupt input cases from shogo82148/base64dq
pub fn dq_decode_pad_at_start_test() -> Nil {
  // "・・・・" -> pad at position 0 is invalid
  assert case yabase.decode("・・・・", using: yabase.Base64Dq) {
    Error(InvalidCharacter("・", 0)) -> True
    _ -> False
  }
}

pub fn dq_decode_pad_after_one_char_test() -> Nil {
  // "が・・・" -> pad at position 1 in first group
  assert case yabase.decode("が・・・", using: yabase.Base64Dq) {
    Error(InvalidCharacter("・", _)) -> True
    _ -> False
  }
}

// --- DQ error cases ---

pub fn dq_decode_non_hiragana_ascii_test() -> Nil {
  // ASCII "ABCD" is not in the DQ hiragana alphabet
  assert case yabase.decode("ABCD", using: yabase.Base64Dq) {
    Error(InvalidCharacter("A", 0)) -> True
    _ -> False
  }
}

pub fn dq_decode_non_hiragana_kanji_test() -> Nil {
  // Kanji is not in the DQ alphabet
  assert case yabase.decode("漢字漢字", using: yabase.Base64Dq) {
    Error(InvalidCharacter(_, 0)) -> True
    _ -> False
  }
}

pub fn dq_decode_stray_char_in_middle_test() -> Nil {
  // 4-char aligned input with invalid first char
  assert case yabase.decode("Xいうえ", using: yabase.Base64Dq) {
    Error(InvalidCharacter("X", 0)) -> True
    _ -> False
  }
}

// ===== decode_strict (RFC 4648 §3.5 canonical-encoding check) =====

pub fn standard_decode_strict_canonical_passes_test() -> Nil {
  // Canonical encoding of "f" — pad bits in 'g' are zero.
  assert yabase.decode_base64_strict("Zg==") == Ok(<<"f":utf8>>)
}

pub fn standard_decode_strict_non_canonical_rejected_test() -> Nil {
  // Non-canonical: "Zh==" decodes to <<0x66>> too, but the pad bits
  // in 'h' are non-zero (canonical form is "Zg==").
  assert yabase.decode_base64_strict("Zh==") == Error(NonCanonical)
}

pub fn standard_decode_strict_one_pad_non_canonical_rejected_test() -> Nil {
  // Non-canonical 2-byte input with 1 pad char: "Zm9=" decodes to
  // "fo" the same as the canonical "Zm8=", but the trailing 2 bits
  // of '9' (value 61 = 111101) are non-zero. The canonical form
  // ends in '8' (value 60 = 111100).
  assert yabase.decode_base64_strict("Zm9=") == Error(NonCanonical)
}

pub fn standard_decode_strict_full_block_passes_test() -> Nil {
  // Full-block encodings (no padding) cannot be non-canonical —
  // every bit is data, no pad bits exist.
  assert yabase.decode_base64_strict("Zm9v") == Ok(<<"foo":utf8>>)
}

pub fn standard_decode_strict_propagates_invalid_character_test() -> Nil {
  // Strict mode should still surface alphabet-validation errors
  // unchanged.
  assert case yabase.decode_base64_strict("Z!==") {
    Error(InvalidCharacter("!", 1)) -> True
    _ -> False
  }
}

pub fn standard_decode_strict_propagates_invalid_length_test() -> Nil {
  // Strict mode should still surface length errors unchanged.
  assert case yabase.decode_base64_strict("Zg=") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}
