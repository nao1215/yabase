import yabase/base64/dq
import yabase/base64/nopadding
import yabase/base64/standard
import yabase/base64/urlsafe
import yabase/base64/urlsafe_nopadding
import yabase/core/encoding.{InvalidCharacter, InvalidLength}

// ===== Standard =====

// --- Fixed vectors (RFC 4648 section 10) ---

pub fn standard_encode_empty_test() {
  assert standard.encode(<<>>) == ""
}

pub fn standard_encode_f_test() {
  assert standard.encode(<<"f":utf8>>) == "Zg=="
}

pub fn standard_encode_fo_test() {
  assert standard.encode(<<"fo":utf8>>) == "Zm8="
}

pub fn standard_encode_foo_test() {
  assert standard.encode(<<"foo":utf8>>) == "Zm9v"
}

pub fn standard_encode_foob_test() {
  assert standard.encode(<<"foob":utf8>>) == "Zm9vYg=="
}

pub fn standard_encode_fooba_test() {
  assert standard.encode(<<"fooba":utf8>>) == "Zm9vYmE="
}

pub fn standard_encode_foobar_test() {
  assert standard.encode(<<"foobar":utf8>>) == "Zm9vYmFy"
}

pub fn standard_decode_empty_test() {
  assert standard.decode("") == Ok(<<>>)
}

pub fn standard_decode_foobar_test() {
  assert standard.decode("Zm9vYmFy") == Ok(<<"foobar":utf8>>)
}

pub fn standard_decode_with_padding_test() {
  assert standard.decode("Zg==") == Ok(<<"f":utf8>>)
}

// --- Decode error cases ---

pub fn standard_decode_truncated_1char_test() {
  assert standard.decode("Z") == Error(InvalidLength(1))
}

pub fn standard_decode_truncated_2char_test() {
  assert standard.decode("Zg") == Error(InvalidLength(2))
}

pub fn standard_decode_truncated_3char_test() {
  assert standard.decode("Zg=") == Error(InvalidLength(3))
}

pub fn standard_decode_invalid_char_test() {
  assert standard.decode("Z!==") == Error(InvalidCharacter("!", 1))
}

// --- CRLF rejection (RFC 4648 section 3.3) ---

pub fn standard_decode_rejects_lf_test() {
  // "Zm9v\n" is 5 chars -> 5 % 4 != 0 -> InvalidLength
  assert standard.decode("Zm9v\n") == Error(InvalidLength(5))
}

pub fn standard_decode_rejects_crlf_in_middle_test() {
  // "Zg==\r\n" - \r\n is one grapheme cluster in Unicode -> 5 graphemes
  assert standard.decode("Zg==\r\n") == Error(InvalidLength(5))
}

// --- Padding-then-trailing-data regression ---

pub fn standard_decode_data_after_double_pad_test() {
  // "Zg==AAAA" must be rejected, not silently truncated
  assert case standard.decode("Zg==AAAA") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn standard_decode_data_after_single_pad_test() {
  // "Zm8=AAAA" must be rejected
  assert case standard.decode("Zm8=AAAA") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// --- Roundtrip corpus ---

pub fn standard_roundtrip_test() {
  let data = <<"Hello, World!":utf8>>
  assert standard.decode(standard.encode(data)) == Ok(data)
}

pub fn standard_roundtrip_empty_test() {
  assert standard.decode(standard.encode(<<>>)) == Ok(<<>>)
}

pub fn standard_roundtrip_single_zero_test() {
  assert standard.decode(standard.encode(<<0>>)) == Ok(<<0>>)
}

pub fn standard_roundtrip_leading_zeros_test() {
  let data = <<0, 0, 0, 42>>
  assert standard.decode(standard.encode(data)) == Ok(data)
}

pub fn standard_roundtrip_high_bits_test() {
  let data = <<0xff, 0xfe, 0x80>>
  assert standard.decode(standard.encode(data)) == Ok(data)
}

// ===== URL-safe =====

pub fn urlsafe_encode_test() {
  let data = <<251, 255, 254>>
  let encoded = urlsafe.encode(data)
  assert encoded == "-__-"
}

pub fn urlsafe_roundtrip_test() {
  let data = <<"Hello, World!":utf8>>
  assert urlsafe.decode(urlsafe.encode(data)) == Ok(data)
}

pub fn urlsafe_roundtrip_empty_test() {
  assert urlsafe.decode(urlsafe.encode(<<>>)) == Ok(<<>>)
}

pub fn urlsafe_decode_truncated_test() {
  assert urlsafe.decode("ab") == Error(InvalidLength(2))
}

pub fn urlsafe_decode_rejects_lf_test() {
  // "Zm9v\n" is 5 chars -> 5 % 4 != 0 -> InvalidLength
  assert urlsafe.decode("Zm9v\n") == Error(InvalidLength(5))
}

pub fn urlsafe_decode_data_after_double_pad_test() {
  assert case urlsafe.decode("Zg==AAAA") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

pub fn urlsafe_decode_data_after_single_pad_test() {
  assert case urlsafe.decode("Zm8=AAAA") {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// ===== No padding =====

pub fn nopadding_encode_f_test() {
  assert nopadding.encode(<<"f":utf8>>) == "Zg"
}

pub fn nopadding_encode_fo_test() {
  assert nopadding.encode(<<"fo":utf8>>) == "Zm8"
}

pub fn nopadding_roundtrip_test() {
  let data = <<"Hello, World!":utf8>>
  assert nopadding.decode(nopadding.encode(data)) == Ok(data)
}

pub fn nopadding_roundtrip_empty_test() {
  assert nopadding.decode(nopadding.encode(<<>>)) == Ok(<<>>)
}

pub fn nopadding_decode_invalid_length_mod4_eq_1_test() {
  // Length 5 -> 5 % 4 == 1 -> invalid
  assert nopadding.decode("AAAAA") == Error(InvalidLength(5))
}

pub fn nopadding_decode_rejects_padding_test() {
  // "Zg==" is valid padded Base64 for "f", but nopadding must reject it
  assert nopadding.decode("Zg==") == Error(InvalidCharacter("=", 2))
}

pub fn nopadding_decode_rejects_single_pad_test() {
  assert nopadding.decode("Zm8=") == Error(InvalidCharacter("=", 3))
}

// ===== URL-safe no padding =====

pub fn urlsafe_nopadding_decode_rejects_padding_test() {
  assert urlsafe_nopadding.decode("Zg==") == Error(InvalidCharacter("=", 2))
}

// ===== DQ =====

pub fn dq_encode_empty_test() {
  assert dq.encode(<<>>) == ""
}

pub fn dq_roundtrip_test() {
  let data = <<"Hello":utf8>>
  assert dq.decode(dq.encode(data)) == Ok(data)
}

pub fn dq_roundtrip_with_padding_test() {
  let data = <<"Hi":utf8>>
  assert dq.decode(dq.encode(data)) == Ok(data)
}

pub fn dq_roundtrip_empty_test() {
  assert dq.decode(dq.encode(<<>>)) == Ok(<<>>)
}

pub fn dq_decode_truncated_test() {
  // 1 or 2 or 3 hiragana is invalid (must be multiple of 4)
  assert dq.decode("あ") == Error(InvalidLength(1))
}

pub fn dq_decode_truncated_2_test() {
  assert dq.decode("あい") == Error(InvalidLength(2))
}

pub fn dq_decode_truncated_3_test() {
  assert dq.decode("あいう") == Error(InvalidLength(3))
}

pub fn dq_decode_data_after_double_pad_test() {
  // Encode "f" -> 4 chars with 2 pads, then append valid chars
  let encoded = dq.encode(<<"f":utf8>>)
  let with_extra = encoded <> "あいうえ"
  assert case dq.decode(with_extra) {
    Error(InvalidLength(_)) -> True
    _ -> False
  }
}

// --- DQ error cases ---

pub fn dq_decode_non_hiragana_ascii_test() {
  // ASCII "ABCD" is not in the DQ hiragana alphabet
  assert case dq.decode("ABCD") {
    Error(InvalidCharacter("A", 0)) -> True
    _ -> False
  }
}

pub fn dq_decode_non_hiragana_kanji_test() {
  // Kanji is not in the DQ alphabet
  assert case dq.decode("漢字漢字") {
    Error(InvalidCharacter(_, 0)) -> True
    _ -> False
  }
}

pub fn dq_decode_stray_char_in_middle_test() {
  // 4-char aligned input with invalid first char
  assert case dq.decode("Xいうえ") {
    Error(InvalidCharacter("X", 0)) -> True
    _ -> False
  }
}
