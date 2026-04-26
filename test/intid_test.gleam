import yabase/core/encoding.{InvalidCharacter}
import yabase/intid

// === Base32 (RFC 4648) ===

pub fn encode_int_base32_rfc4648_zero_test() -> Nil {
  assert intid.encode_int_base32_rfc4648(0) == "AA======"
}

pub fn encode_int_base32_rfc4648_one_test() -> Nil {
  assert intid.encode_int_base32_rfc4648(1) == "AE======"
}

pub fn encode_int_base32_rfc4648_max_byte_test() -> Nil {
  assert intid.encode_int_base32_rfc4648(255) == "74======"
}

pub fn decode_int_base32_rfc4648_empty_test() -> Nil {
  assert intid.decode_int_base32_rfc4648("") == Ok(0)
}

pub fn decode_int_base32_rfc4648_roundtrip_test() -> Nil {
  let encoded = intid.encode_int_base32_rfc4648(1_234_567)
  assert intid.decode_int_base32_rfc4648(encoded) == Ok(1_234_567)
}

pub fn decode_int_base32_rfc4648_invalid_char_test() -> Nil {
  assert intid.decode_int_base32_rfc4648("!!!!!!!!")
    == Error(InvalidCharacter("!", 0))
}

// === Base32 (Crockford) ===

pub fn encode_int_base32_crockford_zero_test() -> Nil {
  assert intid.encode_int_base32_crockford(0) == "0"
}

pub fn encode_int_base32_crockford_alphabet_max_test() -> Nil {
  assert intid.encode_int_base32_crockford(31) == "Z"
}

pub fn encode_int_base32_crockford_carry_test() -> Nil {
  assert intid.encode_int_base32_crockford(32) == "10"
}

pub fn encode_int_base32_crockford_two_digit_max_test() -> Nil {
  assert intid.encode_int_base32_crockford(1023) == "ZZ"
}

pub fn decode_int_base32_crockford_empty_test() -> Nil {
  assert intid.decode_int_base32_crockford("") == Ok(0)
}

pub fn decode_int_base32_crockford_leading_zero_tolerant_test() -> Nil {
  assert intid.decode_int_base32_crockford("0042")
    == intid.decode_int_base32_crockford("42")
}

pub fn decode_int_base32_crockford_roundtrip_test() -> Nil {
  let encoded = intid.encode_int_base32_crockford(987_654)
  assert intid.decode_int_base32_crockford(encoded) == Ok(987_654)
}

// === Base36 ===

pub fn encode_int_base36_zero_test() -> Nil {
  assert intid.encode_int_base36(0) == "0"
}

pub fn encode_int_base36_alphabet_max_test() -> Nil {
  assert intid.encode_int_base36(35) == "z"
}

pub fn encode_int_base36_carry_test() -> Nil {
  assert intid.encode_int_base36(36) == "10"
}

pub fn encode_int_base36_two_digit_max_test() -> Nil {
  assert intid.encode_int_base36(1295) == "zz"
}

pub fn decode_int_base36_empty_test() -> Nil {
  assert intid.decode_int_base36("") == Ok(0)
}

pub fn decode_int_base36_leading_zero_tolerant_test() -> Nil {
  assert intid.decode_int_base36("0042") == intid.decode_int_base36("42")
}

pub fn decode_int_base36_roundtrip_test() -> Nil {
  let encoded = intid.encode_int_base36(8_675_309)
  assert intid.decode_int_base36(encoded) == Ok(8_675_309)
}

pub fn decode_int_base36_invalid_char_test() -> Nil {
  assert intid.decode_int_base36("!") == Error(InvalidCharacter("!", 0))
}

// === Base58 (Bitcoin) ===

pub fn encode_int_base58_zero_test() -> Nil {
  assert intid.encode_int_base58(0) == "1"
}

pub fn encode_int_base58_small_test() -> Nil {
  assert intid.encode_int_base58(42) == "j"
}

pub fn encode_int_base58_alphabet_max_test() -> Nil {
  assert intid.encode_int_base58(57) == "z"
}

pub fn encode_int_base58_carry_test() -> Nil {
  assert intid.encode_int_base58(58) == "21"
}

pub fn encode_int_base58_two_digit_test() -> Nil {
  assert intid.encode_int_base58(1234) == "NH"
}

pub fn decode_int_base58_empty_test() -> Nil {
  assert intid.decode_int_base58("") == Ok(0)
}

pub fn decode_int_base58_leading_zero_tolerant_test() -> Nil {
  assert intid.decode_int_base58("11NH") == intid.decode_int_base58("NH")
}

pub fn decode_int_base58_roundtrip_test() -> Nil {
  let encoded = intid.encode_int_base58(9_999_999_999)
  assert intid.decode_int_base58(encoded) == Ok(9_999_999_999)
}

pub fn decode_int_base58_invalid_char_test() -> Nil {
  assert intid.decode_int_base58("0") == Error(InvalidCharacter("0", 0))
}

// === Base58 (Flickr) ===

pub fn encode_int_base58_flickr_zero_test() -> Nil {
  assert intid.encode_int_base58_flickr(0) == "1"
}

pub fn encode_int_base58_flickr_small_test() -> Nil {
  assert intid.encode_int_base58_flickr(42) == "J"
}

pub fn decode_int_base58_flickr_roundtrip_test() -> Nil {
  let encoded = intid.encode_int_base58_flickr(1_234_567)
  assert intid.decode_int_base58_flickr(encoded) == Ok(1_234_567)
}

pub fn decode_int_base58_flickr_empty_test() -> Nil {
  assert intid.decode_int_base58_flickr("") == Ok(0)
}

// === Base62 ===

pub fn encode_int_base62_zero_test() -> Nil {
  assert intid.encode_int_base62(0) == "0"
}

pub fn encode_int_base62_alphabet_max_test() -> Nil {
  assert intid.encode_int_base62(61) == "z"
}

pub fn encode_int_base62_carry_test() -> Nil {
  assert intid.encode_int_base62(62) == "10"
}

pub fn encode_int_base62_large_test() -> Nil {
  assert intid.encode_int_base62(1_234_567_890) == "1LY7VK"
}

pub fn decode_int_base62_empty_test() -> Nil {
  assert intid.decode_int_base62("") == Ok(0)
}

pub fn decode_int_base62_roundtrip_test() -> Nil {
  let encoded = intid.encode_int_base62(2_147_483_647)
  assert intid.decode_int_base62(encoded) == Ok(2_147_483_647)
}

pub fn decode_int_base62_leading_zero_tolerant_test() -> Nil {
  assert intid.decode_int_base62("00abc") == intid.decode_int_base62("abc")
}

// === Cross-cutting: negative inputs are absorbed as |n| ===

pub fn encode_int_base58_negative_normalized_test() -> Nil {
  assert intid.encode_int_base58(-42) == intid.encode_int_base58(42)
}

pub fn encode_int_base62_negative_normalized_test() -> Nil {
  assert intid.encode_int_base62(-1) == intid.encode_int_base62(1)
}
