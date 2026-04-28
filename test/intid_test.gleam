import yabase/core/encoding.{InvalidCharacter, InvalidLength, Overflow}
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
  assert intid.decode_int_base32_rfc4648("") == Error(InvalidLength(0))
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
  assert intid.decode_int_base32_crockford("") == Error(InvalidLength(0))
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
  assert intid.decode_int_base36("") == Error(InvalidLength(0))
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
  assert intid.decode_int_base58("") == Error(InvalidLength(0))
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
  assert intid.decode_int_base58_flickr("") == Error(InvalidLength(0))
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
  assert intid.decode_int_base62("") == Error(InvalidLength(0))
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

// === Bounded decode: cap constants ===

pub fn int64_max_constant_test() -> Nil {
  // 2^63 - 1
  assert intid.int64_max == 9_223_372_036_854_775_807
}

pub fn int53_max_constant_test() -> Nil {
  // 2^53 - 1, JavaScript Number.MAX_SAFE_INTEGER
  assert intid.int53_max == 9_007_199_254_740_991
}

// === Bounded decode: Base58 (Bitcoin) ===

pub fn decode_int_base58_bounded_within_test() -> Nil {
  let encoded = intid.encode_int_base58(42)
  assert intid.decode_int_base58_bounded(input: encoded, max: intid.int64_max)
    == Ok(42)
}

pub fn decode_int_base58_bounded_at_cap_test() -> Nil {
  let encoded = intid.encode_int_base58(intid.int64_max)
  assert intid.decode_int_base58_bounded(input: encoded, max: intid.int64_max)
    == Ok(intid.int64_max)
}

pub fn decode_int_base58_bounded_above_cap_test() -> Nil {
  // 58^12 - 1 = "zzzzzzzzzzzz" (12 z's) ≈ 1.5e21, well above int64_max.
  // This is the exact reproduction case from the issue: an attacker
  // (or honest user typing a wrong URL) supplies 12 z's and the
  // unbounded decoder would return a bignum that crashes int64-bound
  // sinks (sqlite/postgres bigserial/mysql bigint).
  assert intid.decode_int_base58_bounded(
      input: "zzzzzzzzzzzz",
      max: intid.int64_max,
    )
    == Error(Overflow)
}

pub fn decode_int_base58_bounded_just_above_cap_test() -> Nil {
  let encoded = intid.encode_int_base58(intid.int64_max + 1)
  assert intid.decode_int_base58_bounded(input: encoded, max: intid.int64_max)
    == Error(Overflow)
}

pub fn decode_int_base58_bounded_int53_cap_test() -> Nil {
  let encoded = intid.encode_int_base58(intid.int53_max + 1)
  assert intid.decode_int_base58_bounded(input: encoded, max: intid.int53_max)
    == Error(Overflow)
}

pub fn decode_int_base58_bounded_empty_test() -> Nil {
  // Bounded variant defers empty-input rejection to the underlying
  // decoder so the error contract is identical.
  assert intid.decode_int_base58_bounded(input: "", max: intid.int64_max)
    == Error(InvalidLength(0))
}

pub fn decode_int_base58_bounded_invalid_char_test() -> Nil {
  // Decoder errors propagate through the bounded variant unchanged.
  assert intid.decode_int_base58_bounded(input: "0", max: intid.int64_max)
    == Error(InvalidCharacter("0", 0))
}

// === Bounded decode: Base58 (Flickr) ===

pub fn decode_int_base58_flickr_bounded_within_test() -> Nil {
  let encoded = intid.encode_int_base58_flickr(1234)
  assert intid.decode_int_base58_flickr_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Ok(1234)
}

pub fn decode_int_base58_flickr_bounded_above_cap_test() -> Nil {
  let encoded = intid.encode_int_base58_flickr(intid.int64_max + 1)
  assert intid.decode_int_base58_flickr_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Error(Overflow)
}

// === Bounded decode: Base62 ===

pub fn decode_int_base62_bounded_within_test() -> Nil {
  let encoded = intid.encode_int_base62(2_147_483_647)
  assert intid.decode_int_base62_bounded(input: encoded, max: intid.int64_max)
    == Ok(2_147_483_647)
}

pub fn decode_int_base62_bounded_above_cap_test() -> Nil {
  let encoded = intid.encode_int_base62(intid.int64_max + 1)
  assert intid.decode_int_base62_bounded(input: encoded, max: intid.int64_max)
    == Error(Overflow)
}

pub fn decode_int_base62_bounded_int53_within_test() -> Nil {
  let encoded = intid.encode_int_base62(intid.int53_max)
  assert intid.decode_int_base62_bounded(input: encoded, max: intid.int53_max)
    == Ok(intid.int53_max)
}

// === Bounded decode: Base36 ===

pub fn decode_int_base36_bounded_within_test() -> Nil {
  let encoded = intid.encode_int_base36(8_675_309)
  assert intid.decode_int_base36_bounded(input: encoded, max: intid.int64_max)
    == Ok(8_675_309)
}

pub fn decode_int_base36_bounded_above_cap_test() -> Nil {
  let encoded = intid.encode_int_base36(intid.int64_max + 1)
  assert intid.decode_int_base36_bounded(input: encoded, max: intid.int64_max)
    == Error(Overflow)
}

// === Bounded decode: Base32 (RFC 4648) ===

pub fn decode_int_base32_rfc4648_bounded_within_test() -> Nil {
  let encoded = intid.encode_int_base32_rfc4648(1_234_567)
  assert intid.decode_int_base32_rfc4648_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Ok(1_234_567)
}

pub fn decode_int_base32_rfc4648_bounded_above_cap_test() -> Nil {
  let encoded = intid.encode_int_base32_rfc4648(intid.int64_max + 1)
  assert intid.decode_int_base32_rfc4648_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Error(Overflow)
}

// === Bounded decode: Base32 (Crockford) ===

pub fn decode_int_base32_crockford_bounded_within_test() -> Nil {
  let encoded = intid.encode_int_base32_crockford(987_654)
  assert intid.decode_int_base32_crockford_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Ok(987_654)
}

pub fn decode_int_base32_crockford_bounded_above_cap_test() -> Nil {
  let encoded = intid.encode_int_base32_crockford(intid.int64_max + 1)
  assert intid.decode_int_base32_crockford_bounded(
      input: encoded,
      max: intid.int64_max,
    )
    == Error(Overflow)
}
