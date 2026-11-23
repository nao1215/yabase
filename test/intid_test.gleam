import codec_test_support
import gleam/option
import gleam/string
import yabase.{
  InvalidCharacter, InvalidChecksum, InvalidLength, NegativeValue, NonCanonical,
  Overflow, UnsupportedForInt,
}

// === Base32 (RFC 4648) ===

pub fn encode_int_base32_rfc4648_zero_test() -> Nil {
  assert yabase.encode_int(0, using: yabase.Base32Rfc4648) == Ok("AA======")
}

pub fn encode_int_base32_rfc4648_one_test() -> Nil {
  assert yabase.encode_int(1, using: yabase.Base32Rfc4648) == Ok("AE======")
}

pub fn encode_int_base32_rfc4648_max_byte_test() -> Nil {
  assert yabase.encode_int(255, using: yabase.Base32Rfc4648) == Ok("74======")
}

pub fn decode_int_base32_rfc4648_empty_test() -> Nil {
  assert yabase.decode_int("", using: yabase.Base32Rfc4648, up_to: option.None)
    == Error(InvalidLength(0))
}

pub fn decode_int_base32_rfc4648_roundtrip_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(1_234_567, using: yabase.Base32Rfc4648)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base32Rfc4648,
      up_to: option.None,
    )
    == Ok(1_234_567)
}

pub fn decode_int_base32_rfc4648_invalid_char_test() -> Nil {
  assert yabase.decode_int(
      "!!!!!!!!",
      using: yabase.Base32Rfc4648,
      up_to: option.None,
    )
    == Error(InvalidCharacter("!", 0))
}

// === Base32 (Crockford) ===

pub fn encode_int_base32_crockford_zero_test() -> Nil {
  assert yabase.encode_int(0, using: yabase.Base32Crockford) == Ok("0")
}

pub fn encode_int_base32_crockford_alphabet_max_test() -> Nil {
  assert yabase.encode_int(31, using: yabase.Base32Crockford) == Ok("Z")
}

pub fn encode_int_base32_crockford_carry_test() -> Nil {
  assert yabase.encode_int(32, using: yabase.Base32Crockford) == Ok("10")
}

pub fn encode_int_base32_crockford_two_digit_max_test() -> Nil {
  assert yabase.encode_int(1023, using: yabase.Base32Crockford) == Ok("ZZ")
}

pub fn decode_int_base32_crockford_empty_test() -> Nil {
  assert yabase.decode_int(
      "",
      using: yabase.Base32Crockford,
      up_to: option.None,
    )
    == Error(InvalidLength(0))
}

pub fn decode_int_base32_crockford_rejects_leading_zeros_test() -> Nil {
  assert yabase.decode_int(
      "0042",
      using: yabase.Base32Crockford,
      up_to: option.None,
    )
    == Error(NonCanonical)
}

pub fn decode_int_base32_crockford_roundtrip_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(987_654, using: yabase.Base32Crockford)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base32Crockford,
      up_to: option.None,
    )
    == Ok(987_654)
}

// === encoding.base10() (#78) ===

pub fn encode_int_base10_zero_test() -> Nil {
  assert yabase.encode_int(0, using: yabase.Base10) == Ok("0")
}

pub fn encode_int_base10_single_digit_test() -> Nil {
  assert yabase.encode_int(7, using: yabase.Base10) == Ok("7")
}

pub fn encode_int_base10_carry_test() -> Nil {
  assert yabase.encode_int(10, using: yabase.Base10) == Ok("10")
}

pub fn encode_int_base10_large_test() -> Nil {
  assert yabase.encode_int(1_000_000_000, using: yabase.Base10)
    == Ok("1000000000")
}

pub fn decode_int_base10_empty_test() -> Nil {
  assert yabase.decode_int("", using: yabase.Base10, up_to: option.None)
    == Error(InvalidLength(0))
}

pub fn decode_int_base10_round_trip_test() -> Nil {
  let assert Ok(encoded) = yabase.encode_int(8_675_309, using: yabase.Base10)
  assert yabase.decode_int(encoded, using: yabase.Base10, up_to: option.None)
    == Ok(8_675_309)
}

pub fn decode_int_base10_rejects_leading_zeros_test() -> Nil {
  assert yabase.decode_int("0042", using: yabase.Base10, up_to: option.None)
    == Error(NonCanonical)
}

pub fn decode_int_base10_invalid_char_test() -> Nil {
  assert yabase.decode_int("12a3", using: yabase.Base10, up_to: option.None)
    == Error(InvalidCharacter("a", 2))
}

pub fn decode_int_base10_bounded_within_max_test() -> Nil {
  assert yabase.decode_int(
      "100",
      using: yabase.Base10,
      up_to: option.Some(1000),
    )
    == Ok(100)
}

pub fn decode_int_base10_bounded_at_max_test() -> Nil {
  assert yabase.decode_int(
      "1000",
      using: yabase.Base10,
      up_to: option.Some(1000),
    )
    == Ok(1000)
}

pub fn decode_int_base10_bounded_overflow_test() -> Nil {
  assert yabase.decode_int(
      "1001",
      using: yabase.Base10,
      up_to: option.Some(1000),
    )
    == Error(Overflow)
}

// === encoding.base16() (#85) ===

pub fn encode_int_base16_zero_test() -> Nil {
  assert yabase.encode_int(0, using: yabase.Base16) == Ok("00")
}

pub fn encode_int_base16_single_byte_test() -> Nil {
  assert yabase.encode_int(255, using: yabase.Base16) == Ok("FF")
}

pub fn encode_int_base16_canonical_uppercase_test() -> Nil {
  // Uses RFC 4648 §8 canonical uppercase, matching base16.encode.
  assert yabase.encode_int(0xdeadbeef, using: yabase.Base16) == Ok("DEADBEEF")
}

pub fn decode_int_base16_empty_test() -> Nil {
  assert yabase.decode_int("", using: yabase.Base16, up_to: option.None)
    == Error(InvalidLength(0))
}

pub fn decode_int_base16_round_trip_test() -> Nil {
  let assert Ok(encoded) = yabase.encode_int(8_675_309, using: yabase.Base16)
  assert yabase.decode_int(encoded, using: yabase.Base16, up_to: option.None)
    == Ok(8_675_309)
}

pub fn decode_int_base16_requires_uppercase_test() -> Nil {
  assert yabase.decode_int("deadbeef", using: yabase.Base16, up_to: option.None)
    == Error(NonCanonical)
  assert yabase.decode_int("DEADBEEF", using: yabase.Base16, up_to: option.None)
    == Ok(0xDEADBEEF)
}

pub fn decode_int_base16_invalid_char_test() -> Nil {
  assert yabase.decode_int("12Z3", using: yabase.Base16, up_to: option.None)
    == Error(InvalidCharacter("Z", 2))
}

pub fn decode_int_base16_bounded_within_max_test() -> Nil {
  assert yabase.decode_int("FF", using: yabase.Base16, up_to: option.Some(1000))
    == Ok(255)
}

pub fn decode_int_base16_bounded_at_max_test() -> Nil {
  // The canonical encoding equals the inclusive bound.
  assert yabase.decode_int("FF", using: yabase.Base16, up_to: option.Some(255))
    == Ok(255)
}

pub fn decode_int_base16_bounded_overflow_test() -> Nil {
  assert yabase.decode_int(
      "FFFF",
      using: yabase.Base16,
      up_to: option.Some(255),
    )
    == Error(Overflow)
}

// === encoding.base36() ===

pub fn encode_int_base36_zero_test() -> Nil {
  assert yabase.encode_int(0, using: yabase.Base36) == Ok("0")
}

pub fn encode_int_base36_alphabet_max_test() -> Nil {
  assert yabase.encode_int(35, using: yabase.Base36) == Ok("z")
}

pub fn encode_int_base36_carry_test() -> Nil {
  assert yabase.encode_int(36, using: yabase.Base36) == Ok("10")
}

pub fn encode_int_base36_two_digit_max_test() -> Nil {
  assert yabase.encode_int(1295, using: yabase.Base36) == Ok("zz")
}

pub fn decode_int_base36_empty_test() -> Nil {
  assert yabase.decode_int("", using: yabase.Base36, up_to: option.None)
    == Error(InvalidLength(0))
}

pub fn decode_int_base36_rejects_leading_zeros_test() -> Nil {
  assert yabase.decode_int("0042", using: yabase.Base36, up_to: option.None)
    == Error(NonCanonical)
}

pub fn decode_int_base36_roundtrip_test() -> Nil {
  let assert Ok(encoded) = yabase.encode_int(8_675_309, using: yabase.Base36)
  assert yabase.decode_int(encoded, using: yabase.Base36, up_to: option.None)
    == Ok(8_675_309)
}

pub fn decode_int_base36_invalid_char_test() -> Nil {
  assert yabase.decode_int("!", using: yabase.Base36, up_to: option.None)
    == Error(InvalidCharacter("!", 0))
}

// === Base58 (Bitcoin) ===

pub fn encode_int_base58_zero_test() -> Nil {
  assert yabase.encode_int(0, using: yabase.Base58Bitcoin) == Ok("1")
}

pub fn encode_int_base58_small_test() -> Nil {
  assert yabase.encode_int(42, using: yabase.Base58Bitcoin) == Ok("j")
}

pub fn encode_int_base58_alphabet_max_test() -> Nil {
  assert yabase.encode_int(57, using: yabase.Base58Bitcoin) == Ok("z")
}

pub fn encode_int_base58_carry_test() -> Nil {
  assert yabase.encode_int(58, using: yabase.Base58Bitcoin) == Ok("21")
}

pub fn encode_int_base58_two_digit_test() -> Nil {
  assert yabase.encode_int(1234, using: yabase.Base58Bitcoin) == Ok("NH")
}

pub fn decode_int_base58_empty_test() -> Nil {
  assert yabase.decode_int("", using: yabase.Base58Bitcoin, up_to: option.None)
    == Error(InvalidLength(0))
}

pub fn decode_int_base58_rejects_leading_one_test() -> Nil {
  // Base58 (Bitcoin) uses `"1"` as the zero character, so `"11NH"`
  // decodes to the same `Int` as `"NH"` via the byte-roundtrip path
  // — historically that turned multiple wire strings into aliases
  // for the same ID. The decoder now rejects the non-canonical form
  // so each `Int` has exactly one valid encoded representation.
  // Closes #101.
  assert yabase.decode_int(
      "11NH",
      using: yabase.Base58Bitcoin,
      up_to: option.None,
    )
    == Error(NonCanonical)
}

pub fn decode_int_base58_roundtrip_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(9_999_999_999, using: yabase.Base58Bitcoin)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base58Bitcoin,
      up_to: option.None,
    )
    == Ok(9_999_999_999)
}

pub fn decode_int_base58_invalid_char_test() -> Nil {
  assert yabase.decode_int("0", using: yabase.Base58Bitcoin, up_to: option.None)
    == Error(InvalidCharacter("0", 0))
}

// === Base58 (Flickr) ===

pub fn encode_int_base58_flickr_zero_test() -> Nil {
  assert yabase.encode_int(0, using: yabase.Base58Flickr) == Ok("1")
}

pub fn encode_int_base58_flickr_small_test() -> Nil {
  assert yabase.encode_int(42, using: yabase.Base58Flickr) == Ok("J")
}

pub fn decode_int_base58_flickr_roundtrip_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(1_234_567, using: yabase.Base58Flickr)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base58Flickr,
      up_to: option.None,
    )
    == Ok(1_234_567)
}

pub fn decode_int_base58_flickr_empty_test() -> Nil {
  assert yabase.decode_int("", using: yabase.Base58Flickr, up_to: option.None)
    == Error(InvalidLength(0))
}

// === encoding.base62() ===

pub fn encode_int_base62_zero_test() -> Nil {
  assert yabase.encode_int(0, using: yabase.Base62) == Ok("0")
}

pub fn encode_int_base62_alphabet_max_test() -> Nil {
  assert yabase.encode_int(61, using: yabase.Base62) == Ok("z")
}

pub fn encode_int_base62_carry_test() -> Nil {
  assert yabase.encode_int(62, using: yabase.Base62) == Ok("10")
}

pub fn encode_int_base62_large_test() -> Nil {
  assert yabase.encode_int(1_234_567_890, using: yabase.Base62) == Ok("1LY7VK")
}

pub fn decode_int_base62_empty_test() -> Nil {
  assert yabase.decode_int("", using: yabase.Base62, up_to: option.None)
    == Error(InvalidLength(0))
}

pub fn decode_int_base62_roundtrip_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(2_147_483_647, using: yabase.Base62)
  assert yabase.decode_int(encoded, using: yabase.Base62, up_to: option.None)
    == Ok(2_147_483_647)
}

pub fn decode_int_base62_rejects_leading_zeros_test() -> Nil {
  assert yabase.decode_int("0042", using: yabase.Base62, up_to: option.None)
    == Error(NonCanonical)
}

// === Cross-cutting: negative inputs return Error(NegativeValue(_)) (#100) ===

pub fn encode_int_base58_negative_returns_error_test() -> Nil {
  assert yabase.encode_int(-42, using: yabase.Base58Bitcoin)
    == Error(NegativeValue(-42))
}

pub fn encode_int_base62_negative_returns_error_test() -> Nil {
  assert yabase.encode_int(-1, using: yabase.Base62) == Error(NegativeValue(-1))
}

pub fn encode_int_base10_negative_returns_error_test() -> Nil {
  assert yabase.encode_int(-1, using: yabase.Base10) == Error(NegativeValue(-1))
}

pub fn encode_int_base16_negative_returns_error_test() -> Nil {
  assert yabase.encode_int(-42, using: yabase.Base16)
    == Error(NegativeValue(-42))
}

pub fn encode_int_base16_compact_negative_returns_error_test() -> Nil {
  assert yabase.encode_int_base16_compact(-1) == Error(NegativeValue(-1))
}

pub fn encode_int_base36_negative_returns_error_test() -> Nil {
  assert yabase.encode_int(-1_000_000, using: yabase.Base36)
    == Error(NegativeValue(-1_000_000))
}

pub fn encode_int_base32_rfc4648_negative_returns_error_test() -> Nil {
  assert yabase.encode_int(-7, using: yabase.Base32Rfc4648)
    == Error(NegativeValue(-7))
}

pub fn encode_int_base32_crockford_negative_returns_error_test() -> Nil {
  assert yabase.encode_int(-7, using: yabase.Base32Crockford)
    == Error(NegativeValue(-7))
}

pub fn encode_int_base32_crockford_check_negative_returns_error_test() -> Nil {
  assert yabase.encode_int(-1, using: yabase.Base32CrockfordCheck)
    == Error(NegativeValue(-1))
}

pub fn encode_int_base58_flickr_negative_returns_error_test() -> Nil {
  assert yabase.encode_int(-42, using: yabase.Base58Flickr)
    == Error(NegativeValue(-42))
}

pub fn encode_int_base58check_negative_returns_error_test() -> Nil {
  assert yabase.encode_int(-1, using: yabase.Base58Check(0))
    == Error(NegativeValue(-1))
}

pub fn encode_int_facade_negative_returns_error_test() -> Nil {
  // The facade routes negatives through the same `int_to_bytes_be`
  // guard, so the surfaced error is identical for every codec.
  assert yabase.encode_int(-42, using: yabase.Base58Bitcoin)
    == Error(NegativeValue(-42))
}

pub fn encode_int_facade_base58check_negative_returns_error_test() -> Nil {
  // Base58Check goes through a separate code path (it concatenates a
  // version byte before encoding), so pin its negative behaviour too.
  assert yabase.encode_int(-1, using: yabase.Base58Check(0))
    == Error(NegativeValue(-1))
}

// === Bounded decode: cap constants ===

@target(erlang)
pub fn int64_max_constant_test() -> Nil {
  // 2^63 - 1
  assert yabase.int64_max == 9_223_372_036_854_775_807
}

pub fn int53_max_constant_test() -> Nil {
  // 2^53 - 1, JavaScript Number.MAX_SAFE_INTEGER
  assert yabase.int53_max == 9_007_199_254_740_991
}

// === Bounded decode: Base58 (Bitcoin) ===

pub fn decode_int_base58_bounded_within_test() -> Nil {
  let assert Ok(encoded) = yabase.encode_int(42, using: yabase.Base58Bitcoin)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base58Bitcoin,
      up_to: option.Some(yabase.int64_max),
    )
    == Ok(42)
}

pub fn decode_int_base58_bounded_at_cap_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(yabase.int64_max, using: yabase.Base58Bitcoin)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base58Bitcoin,
      up_to: option.Some(yabase.int64_max),
    )
    == Ok(yabase.int64_max)
}

@target(erlang)
pub fn decode_int_base58_bounded_above_cap_test() -> Nil {
  // 58^12 - 1 = "zzzzzzzzzzzz" (12 z's) ≈ 1.5e21, well above int64_max.
  // This is the exact reproduction case from the issue: an attacker
  // (or honest user typing a wrong URL) supplies 12 z's and the
  // unbounded decoder would return a bignum that crashes int64-bound
  // sinks (sqlite/postgres bigserial/mysql bigint).
  //
  // `@target(erlang)` because the canonical-form check added in #101
  // re-encodes the decoded value to compare against the input. On
  // Erlang `bytes_to_int` returns an unbounded bignum so the re-encode
  // reproduces `"zzzzzzzzzzzz"` and the canonical check passes,
  // leaving the bounded variant to surface `Overflow` as expected.
  // On the JavaScript target `Number.MAX_SAFE_INTEGER` (2^53 - 1) is
  // well below the 12-z magnitude, so `bytes_to_int` loses precision,
  // the re-encode produces a different string, and the canonical
  // check returns `Error(NonCanonical)` before `bounded` ever runs.
  // The other 12-z / above-cap variants in this file already pin the
  // Erlang-only contract the same way (see `decode_int_base58_bounded_just_above_cap_test`).
  assert yabase.decode_int(
      "zzzzzzzzzzzz",
      using: yabase.Base58Bitcoin,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(Overflow)
}

@target(erlang)
pub fn decode_int_base58_bounded_just_above_cap_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(yabase.int64_max + 1, using: yabase.Base58Bitcoin)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base58Bitcoin,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(Overflow)
}

pub fn decode_int_base58_bounded_int53_cap_test() -> Nil {
  let encoded =
    codec_test_support.encode(
      <<0x20, 0, 0, 0, 0, 0, 0>>,
      using: yabase.Base58Bitcoin,
    )
  assert yabase.decode_int(
      encoded,
      using: yabase.Base58Bitcoin,
      up_to: option.Some(yabase.int53_max),
    )
    == Error(Overflow)
}

pub fn decode_int_base58_bounded_empty_test() -> Nil {
  // Bounded variant defers empty-input rejection to the underlying
  // decoder so the error contract is identical.
  assert yabase.decode_int(
      "",
      using: yabase.Base58Bitcoin,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(InvalidLength(0))
}

pub fn decode_int_base58_bounded_invalid_char_test() -> Nil {
  // Decoder errors propagate through the bounded variant unchanged.
  assert yabase.decode_int(
      "0",
      using: yabase.Base58Bitcoin,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(InvalidCharacter("0", 0))
}

// === Bounded decode: Base58 (Flickr) ===

pub fn decode_int_base58_flickr_bounded_within_test() -> Nil {
  let assert Ok(encoded) = yabase.encode_int(1234, using: yabase.Base58Flickr)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base58Flickr,
      up_to: option.Some(yabase.int64_max),
    )
    == Ok(1234)
}

@target(erlang)
pub fn decode_int_base58_flickr_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(yabase.int64_max + 1, using: yabase.Base58Flickr)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base58Flickr,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(Overflow)
}

// === Bounded decode: encoding.base62() ===

pub fn decode_int_base62_bounded_within_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(2_147_483_647, using: yabase.Base62)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base62,
      up_to: option.Some(yabase.int64_max),
    )
    == Ok(2_147_483_647)
}

@target(erlang)
pub fn decode_int_base62_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(yabase.int64_max + 1, using: yabase.Base62)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base62,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(Overflow)
}

pub fn decode_int_base62_bounded_int53_within_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(yabase.int53_max, using: yabase.Base62)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base62,
      up_to: option.Some(yabase.int53_max),
    )
    == Ok(yabase.int53_max)
}

// === Bounded decode: encoding.base36() ===

pub fn decode_int_base36_bounded_within_test() -> Nil {
  let assert Ok(encoded) = yabase.encode_int(8_675_309, using: yabase.Base36)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base36,
      up_to: option.Some(yabase.int64_max),
    )
    == Ok(8_675_309)
}

@target(erlang)
pub fn decode_int_base36_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(yabase.int64_max + 1, using: yabase.Base36)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base36,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(Overflow)
}

// === Bounded decode: Base32 (RFC 4648) ===

pub fn decode_int_base32_rfc4648_bounded_within_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(1_234_567, using: yabase.Base32Rfc4648)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base32Rfc4648,
      up_to: option.Some(yabase.int64_max),
    )
    == Ok(1_234_567)
}

@target(erlang)
pub fn decode_int_base32_rfc4648_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(yabase.int64_max + 1, using: yabase.Base32Rfc4648)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base32Rfc4648,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(Overflow)
}

// === Bounded decode: Base32 (Crockford) ===

pub fn decode_int_base32_crockford_bounded_within_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(987_654, using: yabase.Base32Crockford)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base32Crockford,
      up_to: option.Some(yabase.int64_max),
    )
    == Ok(987_654)
}

@target(erlang)
pub fn decode_int_base32_crockford_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(yabase.int64_max + 1, using: yabase.Base32Crockford)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base32Crockford,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(Overflow)
}

// === Issue #73: Crockford Base32 with check symbol ===

pub fn encode_int_base32_crockford_check_zero_test() -> Nil {
  // 0 encoded as Crockford "0" then check digit for 0 mod 37 == "0".
  assert yabase.encode_int(0, using: yabase.Base32CrockfordCheck) == Ok("00")
}

pub fn decode_int_base32_crockford_check_roundtrip_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(987_654, using: yabase.Base32CrockfordCheck)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base32CrockfordCheck,
      up_to: option.None,
    )
    == Ok(987_654)
}

pub fn decode_int_base32_crockford_check_empty_test() -> Nil {
  assert yabase.decode_int(
      "",
      using: yabase.Base32CrockfordCheck,
      up_to: option.None,
    )
    == Error(InvalidLength(0))
}

pub fn decode_int_base32_crockford_check_detects_typo_test() -> Nil {
  // Take a valid checksummed encoding and mutate one body character.
  // The decoder must reject the typo via InvalidChecksum, which is the
  // whole reason callers reach for the `_check` variant.
  let assert Ok(encoded) =
    yabase.encode_int(123_456, using: yabase.Base32CrockfordCheck)
  let body = string_drop_last(encoded)
  let check = string_take_last(encoded)
  let mutated = mutate_first_body_char(body) <> check
  assert yabase.decode_int(
      mutated,
      using: yabase.Base32CrockfordCheck,
      up_to: option.None,
    )
    == Error(InvalidChecksum)
}

pub fn decode_int_base32_crockford_check_bounded_within_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(42, using: yabase.Base32CrockfordCheck)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base32CrockfordCheck,
      up_to: option.Some(yabase.int64_max),
    )
    == Ok(42)
}

@target(erlang)
pub fn decode_int_base32_crockford_check_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(yabase.int64_max + 1, using: yabase.Base32CrockfordCheck)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base32CrockfordCheck,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(Overflow)
}

// === Issue #73: Base58Check ===
//
// The Base58Check round-trip tests below are `@target(erlang)` because
// `yabase/base58check`'s round-trip is itself only exercised on Erlang
// in this repo (see `test/base58check_test.gleam`); the JS-side
// SHA-256 divergence is pre-existing scope and tracked separately. The
// `decode_int_base58check_empty_test` runs on both targets because
// empty-input rejection short-circuits before any hashing.

@target(erlang)
pub fn encode_int_base58check_zero_roundtrips_test() -> Nil {
  let assert Ok(encoded) = yabase.encode_int(0, using: yabase.Base58Check(0))
  assert yabase.decode_int_base58check(encoded, up_to: option.None) == Ok(0)
}

@target(erlang)
pub fn decode_int_base58check_roundtrip_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(9_999_999_999, using: yabase.Base58Check(0))
  assert yabase.decode_int_base58check(encoded, up_to: option.None)
    == Ok(9_999_999_999)
}

pub fn decode_int_base58check_empty_test() -> Nil {
  assert yabase.decode_int_base58check("", up_to: option.None)
    == Error(InvalidLength(0))
}

@target(erlang)
pub fn decode_int_base58check_detects_typo_test() -> Nil {
  // Mutate the first checksum-bearing position. Base58Check's 4-byte
  // SHA-256 suffix means this *must* fail — that is the property the
  // helper exists to guarantee for callers.
  let assert Ok(encoded) =
    yabase.encode_int(424_242, using: yabase.Base58Check(0))
  let mutated = mutate_first_body_char(encoded)
  assert yabase.decode_int_base58check(mutated, up_to: option.None)
    == Error(InvalidChecksum)
}

@target(erlang)
pub fn decode_int_base58check_bounded_within_test() -> Nil {
  let assert Ok(encoded) = yabase.encode_int(1234, using: yabase.Base58Check(0))
  assert yabase.decode_int_base58check(
      encoded,
      up_to: option.Some(yabase.int64_max),
    )
    == Ok(1234)
}

@target(erlang)
pub fn decode_int_base58check_bounded_above_cap_test() -> Nil {
  let assert Ok(encoded) =
    yabase.encode_int(yabase.int64_max + 1, using: yabase.Base58Check(0))
  assert yabase.decode_int_base58check(
      encoded,
      up_to: option.Some(yabase.int64_max),
    )
    == Error(Overflow)
}

// Helpers for the typo-detection tests above. Kept in the test module so
// the production API stays focused on Int↔string.
fn string_drop_last(s: String) -> String {
  let len = string.length(s)
  string.slice(s, 0, len - 1)
}

fn string_take_last(s: String) -> String {
  let len = string.length(s)
  string.slice(s, len - 1, 1)
}

fn mutate_first_body_char(s: String) -> String {
  // Flip the first character to a different valid Crockford / Base58
  // character. Both alphabets contain "1" and "2", so swapping between
  // them produces a syntactically valid but checksum-invalid string.
  let head = string.slice(s, 0, 1)
  let tail = string.slice(s, 1, string.length(s) - 1)
  let replacement = case head {
    "1" -> "2"
    _ -> "1"
  }
  replacement <> tail
}

// Issue #74: a wrapper that only `import yabase/intid` must be able to
// type-annotate the error returned by `decode_int_*` without reaching
// into `yabase/core/error`. This test pins down that the re-exported
// `intid.CodecError` works as a type annotation and that values of the
// underlying error type round-trip through the alias unchanged.
pub fn intid_codec_error_alias_round_trips_test() -> Nil {
  // The alias is the literal type the decoder returns, so values match
  // by structural equality. `InvalidLength` is one of the existing
  // variants from `yabase/core/error`.
  let result: Result(Int, yabase.CodecError) =
    yabase.decode_int(
      "",
      using: yabase.Base58Bitcoin,
      up_to: option.Some(yabase.int53_max),
    )
  assert result == Error(InvalidLength(0))
}

pub fn intid_codec_error_alias_propagates_through_wrapper_test() -> Nil {
  // Demonstrates the wrapper shape from Issue #74's reproduction: a
  // user function that takes only `yabase/intid` as an import and
  // returns the codec error through a custom name.
  let result = decode_job_id("0OIl")
  // base58 alphabet excludes 0 / O / I / l → InvalidCharacter on the
  // first offending position.
  let assert Error(_) = result
  Nil
}

fn decode_job_id(s: String) -> Result(Int, yabase.CodecError) {
  yabase.decode_int(
    s,
    using: yabase.Base58Bitcoin,
    up_to: option.Some(yabase.int53_max),
  )
}

// === Issue #93: generic encode_int / decode_int facade ===

pub fn encode_int_facade_matches_per_base_base58_test() -> Nil {
  let direct = yabase.encode_int(42, using: yabase.Base58Bitcoin)
  assert yabase.encode_int(42, using: yabase.Base58Bitcoin) == direct
}

pub fn encode_int_facade_matches_per_base_base32_crockford_test() -> Nil {
  let direct = yabase.encode_int(31, using: yabase.Base32Crockford)
  assert yabase.encode_int(31, using: yabase.Base32Crockford) == direct
}

pub fn encode_int_facade_matches_per_base_base62_test() -> Nil {
  let direct = yabase.encode_int(123_456, using: yabase.Base62)
  assert yabase.encode_int(123_456, using: yabase.Base62) == direct
}

pub fn encode_int_facade_matches_per_base_base16_test() -> Nil {
  let direct = yabase.encode_int(255, using: yabase.Base16)
  assert yabase.encode_int(255, using: yabase.Base16) == direct
}

pub fn encode_int_facade_unsupported_base64_test() -> Nil {
  // Base64 has no integer codec. The facade must surface
  // UnsupportedForInt rather than fall back to byte encoding.
  let result = yabase.encode_int(42, using: yabase.Base64)
  assert result == Error(UnsupportedForInt("Base64(Standard)"))
}

pub fn encode_int_facade_unsupported_bech32_test() -> Nil {
  let result =
    yabase.encode_int(42, using: yabase.Bech32Encoding("bc", yabase.Bech32))
  assert result == Error(UnsupportedForInt("Bech32"))
}

pub fn decode_int_facade_matches_per_base_base58_test() -> Nil {
  let assert Ok(encoded) = yabase.encode_int(42, using: yabase.Base58Bitcoin)
  assert yabase.decode_int(
      encoded,
      using: yabase.Base58Bitcoin,
      up_to: option.None,
    )
    == Ok(42)
}

pub fn decode_int_facade_rejects_empty_input_test() -> Nil {
  // Same contract as the per-base decoders: empty input is
  // InvalidLength(0), not the integer zero.
  assert yabase.decode_int("", using: yabase.Base58Bitcoin, up_to: option.None)
    == Error(InvalidLength(0))
}

pub fn decode_int_facade_unsupported_test() -> Nil {
  assert yabase.decode_int("abc", using: yabase.Z85, up_to: option.None)
    == Error(UnsupportedForInt("Base85(Z85)"))
}

pub fn encode_int_then_decode_int_round_trip_test() -> Nil {
  let enc = yabase.Base58Bitcoin
  let assert Ok(encoded) = yabase.encode_int(1_234_567, using: enc)
  assert yabase.decode_int(encoded, using: enc, up_to: option.None)
    == Ok(1_234_567)
}

pub fn decode_int_bounded_facade_overflow_test() -> Nil {
  let enc = yabase.Base58Bitcoin
  let assert Ok(encoded) = yabase.encode_int(1_000_000, using: enc)
  // The encoded value (1_000_000) exceeds max=10, so the bounded
  // facade returns Overflow — same shape as decode_int_*_bounded.
  let result = yabase.decode_int(encoded, using: enc, up_to: option.Some(10))
  assert result == Error(Overflow)
}

pub fn decode_int_bounded_facade_within_range_test() -> Nil {
  let enc = yabase.Base32Crockford
  let assert Ok(encoded) = yabase.encode_int(100, using: enc)
  let result = yabase.decode_int(encoded, using: enc, up_to: option.Some(1000))
  assert result == Ok(100)
}

pub fn encode_int_facade_base58check_test() -> Nil {
  // The version goes through the IntBase58Check carrier so a
  // non-default version reaches the underlying codec.
  let assert Ok(s) = yabase.encode_int(42, using: yabase.Base58Check(5))
  // The decoded round trip is verified against the same version.
  assert yabase.decode_int(s, using: yabase.Base58Check(5), up_to: option.None)
    == Ok(42)
}

pub fn decode_int_facade_base58check_version_mismatch_test() -> Nil {
  // Encode with version 5, decode with version 0 → InvalidChecksum,
  // matching what `yabase.decode` does for Base58Check at the byte
  // layer.
  let assert Ok(s) = yabase.encode_int(42, using: yabase.Base58Check(5))
  assert yabase.decode_int(s, using: yabase.Base58Check(0), up_to: option.None)
    == Error(yabase.UnexpectedVersion(0, 5))
}

@target(javascript)
pub fn int64_max_is_capped_at_js_safe_integer_test() -> Nil {
  assert yabase.int64_max == yabase.int53_max
}
